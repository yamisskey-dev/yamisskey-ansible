# yamisskey.appliances role: migrate-minio

TrueNAS 向け MinIO 移行をロール化したものです（Phase A/B どちらにも対応）。

- tasks/main.yml: フル移行（00→05→10→20→40→50→90）
- tasks/phase-a.yml: ウォームアップのみ（00→10→20）
- tasks/cutover.yml: カットオーバー（00→10→40→50→90）

## 実行方法（プレイブック経由）

- フェーズA（ウォームアップ）:
  - `make run TARGET=appliances PLAYBOOK=migrate-minio-phase-a`
- フル移行（TrueNAS特化の検証＋最終同期まで）:
  - `make run TARGET=appliances PLAYBOOK=migrate-minio-truenas`
- カットオーバー（最終同期＋設定反映＋検証）:
  - `make run TARGET=appliances PLAYBOOK=migrate-minio-cutover`

いずれも内部で本ロールを `include_role` で呼び出します。

## 代表変数（抜粋）

移行元（Source）:
- `source_minio_host`: 例 `source-host`
- `source_minio_address`: 例 `source-host` または IP
- `source_minio_port`: 例 `9000`
- `source_minio_root_user` / `source_minio_root_password`（Vault 推奨）

移行先（Target: TrueNAS + Cloudflare Tunnel）:
- `truenas_minio_root_user` / `truenas_minio_root_password`（Vault 必須）
- `truenas_minio_kms_key`（KMS鍵、任意。指定時は KMS で暗号化）
- `truenas_minio_domain`: 例 `minio.example.com`
- `target_minio_endpoint`: 例 `https://{{ truenas_minio_domain }}`
- `truenas_minio_data_path`: 例 `/mnt/tank/minio`

移行動作:
- `buckets_to_migrate`: 例 `["files"]`
- `migration_temp_dir`: 例 `/tmp/truenas-minio-migration`
- `mc_workers`: 同期並列数（既定 8）
- `perform_incremental_sync`: 最終前の非破壊ミラー（既定 true）
- `perform_final_remove`: `--remove` 同期を行うか（既定 false）
- `cors_allowed_origins`: 例 `["https://<your-misskey-domain>"]`
- `misskey_s3_access_key` / `misskey_s3_secret_key`（任意、IAM 作成時に使用）

セキュリティ（Vault 推奨）:
- `truenas_api_key`, `source_minio_root_password`, `truenas_minio_root_password`, `misskey_s3_secret_key` など機微情報は Vault 管理してください。

## 備考

- 本ロールは servers 側の命名とも互換になるように、必要箇所で変数マッピングを行います（`00_preamble.yml` 参照）。
- 旧 `playbooks/tasks/` と `playbooks/templates/` は廃止し、ロール配下に集約しました。
