TrueNAS SCALE MinIO – Deploy and Migrate

Overview
- Goal: After minimal TrueNAS WebUI actions (create ZFS pool “tank”, create MinIO Custom App with pasted compose), run Ansible to configure the app, apply env, and migrate buckets from Raspberry Pi with a safe two-phase sync.

Prerequisites
- In TrueNAS WebUI: create ZFS pool (e.g., tank) and enable Apps.
- Create MinIO Custom App and paste docker-compose.yml (WebUI manages compose).
- Configure host_vars and Vault secrets for TrueNAS, MinIO root, and Cloudflare Tunnel.

Key Files
- Playbook: ansible/appliances/playbooks/truenas-minio-deploy-and-migrate.yml
- Modular Migration:
  - ansible/appliances/playbooks/migrate-minio-phase-a.yml   # ウォームアップのみ
  - ansible/appliances/playbooks/migrate-minio-cutover.yml   # カットオーバー～検証
- Roles:
  - ansible/appliances/roles/core: datasets/users/snapshots/backup via midclt
  - ansible/appliances/roles/apps: Custom App (MinIO + cloudflared) via midclt
  - Migration (統合版): ansible/appliances/playbooks/migrate-minio-truenas.yml

Variables to set
- host_vars/truenas.yml: truenas_pool_name, truenas_minio_domain, truenas_minio_app_name, Cloudflare tunnel values, MinIO root credentials.
- group_vars/all.yml:
  - mc_release_sha256: set to the pinned mc release sha256
  - Optional: mc_workers, perform_cutover, enable_bucket_versioning, enable_minimal_ilm, cors_allowed_origins
  - truenas_manage_custom_compose: false (WebUI manages the compose)

Run
1) Deploy + migrate, keeping WebUI compose:
   ansible-playbook -i ansible/appliances/inventory ansible/appliances/playbooks/truenas-minio-deploy-and-migrate.yml --ask-become-pass

2) If you prefer separate steps:
   - Core only:    ansible-playbook -i inventory playbooks/setup.yml --tags core
   - Apps only:    ansible-playbook -i inventory playbooks/setup.yml --tags apps
   - Warm-up only: ansible-playbook -i inventory playbooks/migrate-minio-phase-a.yml
   - Cutover only: ansible-playbook -i inventory playbooks/migrate-minio-cutover.yml

Notes
- Two-phase mirroring avoids accidental deletes: warm-up (no --remove) → manual pause → final sync with --remove → mc diff.
- CORS is applied via mc bucket cors set using a JSON array; override cors_allowed_origins to restrict.
- The Apps role redeploys the Custom App automatically when compose changes.
 - If you want Ansible to manage compose (instead of WebUI), set truenas_manage_custom_compose: true. The role will push the compose and create/update the Custom App accordingly.

Common Variables (appliances ⇄ servers)
- Purpose: appliances と servers で名称が違っても相互に受けられるよう、互換レイヤを用意しています。どちらの命名で定義してもOKです。
- MinIO root credentials:
  - appliances: truenas_minio_root_user, truenas_minio_root_password
  - servers: minio_root_user, minio_root_password
- KMS key (SSE-KMS):
  - appliances: truenas_minio_kms_key
  - servers: minio_kms_master_key
- Public domain / Server URL:
  - appliances: truenas_minio_domain
  - servers: minio_api_server_name
- Cloudflare Tunnel token:
  - appliances: truenas_tunnel_token
  - servers: cloudflare_tunnel_token
- Source MinIO (Raspberry Pi) 接続:
  - Common: source_minio_address, source_minio_root_user, source_minio_root_password, source_minio_port (default 9000)
- Misskey S3 user (任意):
  - Common: misskey_s3_access_key, misskey_s3_secret_key
- Buckets:
  - Common: minio_bucket_name_for_misskey (default "files"), minio_bucket_name_for_outline (default "assets")
- Migration options:
  - Common: perform_cutover (default true), enable_bucket_versioning (default false), enable_minimal_ilm (default false), mc_workers (default 8)
- CORS:
  - Common: cors_allowed_origins (default ["*"])
- mc pinning:
  - Common: mc_release_sha256 (必ず実値に更新)

Where the mapping happens
- apps role: ansible/appliances/roles/apps/tasks/00_compat.yml（双方向の名称マッピング）
- migration preamble: ansible/appliances/playbooks/tasks/migrate/00_preamble.yml（必要最低限の互換セット）

Recommended Vault entries (example)
```yaml
# host_vars/truenas.yml or group_vars with Vault
truenas_minio_root_user: "admin"
truenas_minio_root_password: "REDACTED"
truenas_minio_kms_key: "minio-master-key:base64-..."
truenas_tunnel_token: "REDACTED"

# Raspberry Pi (source)
source_minio_address: "raspberrypi"  # or IP
source_minio_root_user: "admin"
source_minio_root_password: "REDACTED"

# Optional Misskey service user (target)
misskey_s3_access_key: "misskey-user"
misskey_s3_secret_key: "REDACTED"

# Migration tuning
perform_cutover: true
enable_bucket_versioning: false
enable_minimal_ilm: false
mc_workers: 8

# CORS
cors_allowed_origins:
  - "https://<your-misskey-domain>"

# mc
mc_release_sha256: "<sha256-of-pinned-release>"
```
