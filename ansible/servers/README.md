Servers ディレクトリの使い方（運用向け）

概要
- 目的: 既存の単体サーバ（Raspberry Pi 等）での運用・保守用 Playbook/Role 群。
- appliances 配下とは環境分離。appliances は TrueNAS SCALE 向けの“アプライアンス化”に最適化、servers は従来の単体サーバ向け構成。
- 互換: 主要な変数は appliances 側と共通利用できるよう命名互換を意識（下記「共通変数」参照）。

主な構成（抜粋）
- inventory: `ansible/servers/inventory`
- playbooks:
  - `ansible/servers/playbooks/minio.yml`      : MinIO サーバのデプロイ/設定
  - `ansible/servers/playbooks/migrate.yml`    : MinIO 間のデータ移行（旧実装）
  - その他（common, security, monitoring, misskey, matrix など）
- roles:
  - `ansible/servers/roles/minio`              : MinIO 本体（Docker Compose）
  - `ansible/servers/roles/migrate`            : MinIO 移行（スクリプト/`/opt/minio/secrets.yml` 参照型）
  - `ansible/servers/roles/cloudflared`        : Cloudflared セットアップ
  - 他アプリのロール（modsecurity-nginx, monitoring など）

クイックスタート
- 事前: 対象サーバに SSH 可能で、`ansible/servers/inventory` にホストが定義されていること。
- MinIO デプロイ（例）
  - `ansible-playbook -i ansible/servers/inventory ansible/servers/playbooks/minio.yml --ask-become-pass`
- 旧式ミグレーション（注意: appliances の二段階ミラー推奨）
  - `ansible-playbook -i ansible/servers/inventory ansible/servers/playbooks/migrate.yml --ask-become-pass`
  - 旧実装は `/opt/minio/secrets.yml` の slurp 前提。新規移行は appliances 側の二段階ミラー（安全）を推奨。

共通変数（appliances ⇄ servers）
- どちらの命名で定義しても互換レイヤで受けられるように設計（appliances 側で双方向マッピング済み）。
- MinIO root:
  - appliances: `truenas_minio_root_user`, `truenas_minio_root_password`
  - servers   : `minio_root_user`, `minio_root_password`
- KMS（SSE-KMS）:
  - appliances: `truenas_minio_kms_key`
  - servers   : `minio_kms_master_key`
- 公開ドメイン/URL:
  - appliances: `truenas_minio_domain`
  - servers   : `minio_api_server_name`
- Cloudflare Tunnel トークン:
  - appliances: `truenas_tunnel_token`
  - servers   : `cloudflare_tunnel_token`
- バケット名（共通既定）:
  - `minio_bucket_name_for_misskey`: `files`
  - `minio_bucket_name_for_outline`: `assets`

- 互換レイヤの場所（参考）
  - appliances apps role: `ansible/appliances/roles/apps/tasks/00_compat.yml`
  - appliances migration preamble: `ansible/appliances/playbooks/tasks/migrate/00_preamble.yml`
  - appliances README (Common Variables): `ansible/appliances/README.md`

 推奨の Vault 例（抜粋）
```
# group_vars/all.yml（または host_vars/<hostname>.yml）
minio_root_user: "admin"
minio_root_password: "REDACTED"
minio_kms_master_key: "minio-master-key:base64-..."
minio_api_server_name: "drive.example.com"
cloudflare_tunnel_token: "REDACTED"

# バケット名（必要に応じて）
minio_bucket_name_for_misskey: "files"
minio_bucket_name_for_outline: "assets"
```

運用上の注意
- 新規の MinIO データ移行は appliances 側のプレイブック（ウォームアップ→手動停止→最終同期）を推奨。誤削除防止と検証（`mc diff`）が強化されています。
- servers 側の `roles/migrate` はレガシー互換のため保持していますが、`/opt/minio/secrets.yml` の前提やネットワーク要件を満たさないと失敗します。
- Cloudflared の導入形態は servers と appliances で異なります（services vs Custom App 内 sidecar）。構成を混在させる場合は注意してください。

トラブルシュート
- 変数解決の齟齬: appliances の互換レイヤがあるため、servers 名称で定義して動かない場合は変数名スペルや Vault 読み込みを確認してください。
- MinIO ヘルス: `curl http://<host>:9000/minio/health/live` または Cloudflare/Tunnel 経由の `/minio/health/live` で確認。
- CORS/ポリシー: バケットポリシー（匿名）とバケットCORS API は別機能です。CORS 設定は `mc bucket cors set` を使用してください。

補足
- appliances 側の README に、共通変数一覧と Vault 例があります。両環境をまたいで運用する場合に参照してください。
