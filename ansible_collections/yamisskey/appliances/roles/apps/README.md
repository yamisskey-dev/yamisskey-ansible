# yamisskey.appliances role: apps

このロールは、TrueNAS Scale 上のアプリ（MinIO + Cloudflared の Custom App）を管理します。`setup.yml` などのプレイブックから呼び出され、`midclt` API を用いてアプリの作成/更新/再配置を行います。

主な機能（`tasks/main.yml`）:
- Cloudflared 設定の展開: `cloudflared-config.yml.j2` → `{{ truenas_cloudflared_config_path }}/config.yml`
- MinIO Compose の管理（任意）: `minio-compose.yml.j2` を `{{ truenas_apps_config_path }}/minio/docker-compose.yml` に展開（`truenas_manage_custom_compose: true` のとき）
- Custom App 作成/更新: `app.create` / `app.update` / `app.redeploy`（`midclt`）
- 環境変数注入: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `TUNNEL_TOKEN` などを API 経由で注入
- 健全性確認: `https://{{ truenas_minio_domain }}/minio/health/live` に対する HTTP 監視

関連変数（抜粋）:
- `truenas_minio_app_name`, `truenas_minio_domain`
- `truenas_apps_config_path`, `truenas_cloudflared_config_path`
- `truenas_tunnel_id`, `truenas_tunnel_token`, `truenas_tunnel_credentials`（Vault 推奨）
- `truenas_manage_custom_compose`（compose を Ansible 管理するか）

実行例:
- 確認: `make check PLAYBOOK=setup TARGET=appliances`
- 実行: `make run PLAYBOOK=setup TARGET=appliances`
