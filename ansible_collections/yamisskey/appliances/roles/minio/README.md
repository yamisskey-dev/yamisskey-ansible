# yamisskey.appliances.minio

TrueNAS Scale上でMinIOを構築するための専用ロール

## 概要

このロールは**MinIO環境の構築のみ**を担当します。データ移行は別ロール（`yamisskey.appliances.migrate_minio`）で実行してください。

## 責任

- ✅ TrueNAS Scale上でのMinIO Custom Appデプロイメント
- ✅ Cloudflare Tunnel設定
- ✅ Nginx リバースプロキシ設定
- ✅ Docker Compose設定管理
- ✅ ヘルスチェック
- ❌ データ移行（別ロールの責任）

## 必要な変数

### 必須変数

```yaml
truenas_pool_name: "tank"
truenas_minio_domain: "drive.example.com"
truenas_minio_root_user: "{{ vault_minio_root_user }}"
truenas_minio_root_password: "{{ vault_minio_root_password }}"
truenas_minio_kms_key: "{{ vault_minio_kms_key }}"
truenas_tunnel_token: "{{ vault_tunnel_token }}"
```

### オプション変数

```yaml
truenas_minio_app_name: "minio"
truenas_minio_version: "RELEASE.2024-10-02T17-50-41Z"
truenas_manage_custom_compose: true
truenas_update_secrets: true
truenas_skip_health_check: false
```

## 使用例

### 基本的な使用方法

```yaml
---
- hosts: truenas
  roles:
    - yamisskey.appliances.core      # TrueNAS基盤準備
    - yamisskey.appliances.minio     # MinIO構築
```

### 変数指定での使用

```yaml
---
- hosts: truenas
  vars:
    truenas_minio_domain: "s3.mysite.com"
    truenas_minio_app_name: "minio-prod"
  roles:
    - yamisskey.appliances.minio
```

## 前提条件

1. TrueNAS Scale 25.04以上
2. `yamisskey.appliances.core` ロールの事前実行
3. Cloudflare Tunnelの設定済み
4. 必要な認証情報がAnsible Vaultで管理されていること

## 出力成果物

### TrueNAS Scale上
- `/mnt/{pool}/apps/minio/docker-compose.yml`
- `/mnt/{pool}/apps/minio/nginx.conf`
- `/mnt/{pool}/apps/minio/minio.conf`
- `/mnt/{pool}/apps/cloudflared/config.yml`

### ローカル
- `{playbook_dir}/out/minio-docker-compose.paste.yml` - WebUI用貼り付け済みcompose

## 互換性

このロールは `servers` コレクションの変数命名とも互換性があります：

```yaml
# servers風の変数でも動作
minio_root_user: "admin"
minio_root_password: "password"
minio_api_server_name: "s3.example.com"
cloudflare_tunnel_token: "token"
```

## テスト

```bash
cd ansible_collections/yamisskey/appliances/roles/minio
molecule test
```

## 関連ロール

- `yamisskey.appliances.core` - TrueNAS基盤準備（前提）
- `yamisskey.appliances.migrate_minio` - データ移行（後続）
- `yamisskey.appliances.apps` - 汎用アプリ管理

## トラブルシューティング

### ヘルスチェック失敗
```yaml
truenas_skip_health_check: true  # 一時的にスキップ
```

### Custom App作成失敗
```yaml
truenas_manage_custom_compose: false  # WebUI手動作成時
```

## ライセンス

MIT