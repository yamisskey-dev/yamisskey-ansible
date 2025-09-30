# deploy/appliances/host_vars

このディレクトリは、TrueNAS アプライアンス向けの Ansible ホスト変数 (`host_vars`) を格納します。`truenas.yml` がサンプルです。

主な変数例（`truenas.yml` より抜粋）:
- 接続情報: `ansible_host`, `ansible_user`, `ansible_connection`
- ドメイン/アプリ: `truenas_minio_domain`, `truenas_minio_app_name`
- API 認証: `truenas_api_url`（`truenas_api_key` は SOPS で管理）
- Cloudflare Tunnel: `truenas_tunnel_id`, `truenas_tunnel_token`, `truenas_tunnel_credentials`（SOPS 管理）
- MinIO Secrets: `truenas_minio_root_user`, `truenas_minio_root_password`, `truenas_minio_kms_key`（SOPS 管理）
- ストレージ: `truenas_pool_name`, `truenas_minio_data_path`, `truenas_cloudflared_config_path`, `truenas_apps_config_path`

使い方:
- 値を更新後、関連プレイブックを実行します。
  - 確認: `yamisskey-provision check setup TARGET=appliances`
  - 実行: `yamisskey-provision run setup TARGET=appliances`

注意:
- 秘密情報は必ず SOPS (group_vars/all/secrets.yml や host_vars/<host>/secrets.yml) で管理してください。
