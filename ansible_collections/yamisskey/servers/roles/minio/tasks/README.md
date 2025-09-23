# yamisskey.servers role: minio - tasks

`minio` ロールのタスク定義を格納します。`minio.yml` からロールが呼び出され、以下を実施します。

主な処理:
- ディレクトリ作成: `/opt/minio`, `/opt/minio/minio-data`
- シークレット管理: `minio_secrets_file` へ root/アプリ用キーと KMS マスターキーを生成・保存（初回）
- テンプレート展開: `minio_docker-compose.yml.j2` → `/opt/minio/docker-compose.yml`
- Docker 起動: Compose v2 で MinIO を起動、`external_network` 作成
- ヘルスチェック: `/minio/health/live` を確認
- MinIO Client `mc` 導入・エイリアス設定
- バケット/IAM 作成: Misskey/Outline 用バケットとユーザ、ポリシー作成、SSE-S3 有効化

代表変数（例: `group_vars`/`host_vars` で上書き）:
```yaml
minio_alias: yaminio
minio_secrets_file: /opt/minio/secrets.yml
minio_bucket_name_for_misskey: files
minio_bucket_name_for_outline: assets
```

Vault 推奨（必要に応じて上書き）:
```yaml
minio_root_user: "..."            # ルートアクセスキー
minio_root_password: "..."        # ルートシークレット
misskey_s3_access_key: "..."      # Misskey 用アクセスキー
misskey_s3_secret_key: "..."      # Misskey 用シークレット
minio_kms_master_key: "..."       # KMS マスターキー
```

実行例:
- 確認: `yamisskey-provision check minio`
- 実行: `yamisskey-provision run minio`
