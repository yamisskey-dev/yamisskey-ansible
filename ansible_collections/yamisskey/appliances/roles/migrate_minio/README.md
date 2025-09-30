# yamisskey.appliances.migrate_minio

MinIOデータ移行専用ロール

## 概要

このロールは**MinIOデータの移行のみ**を担当します。MinIO環境の構築は別ロール（`yamisskey.appliances.minio`）で実行してください。

## 責任

- ✅ **データ同期のみ** - 移行元から移行先へのデータ転送
- ✅ ファイル整合性チェック
- ✅ 移行検証
- ❌ バケット作成（`yamisskey.appliances.minio`ロールの責任）
- ❌ IAM設定（`yamisskey.appliances.minio`ロールの責任）
- ❌ CORS設定（`yamisskey.appliances.minio`ロールの責任）

## 前提条件

1. **移行先MinIO環境が構築済み**であること
   ```bash
   # 事前に実行必須
   ansible-playbook minio-deploy.yml
   ```

2. 移行元・移行先の両方でMinIOが稼働中であること
3. 必要な認証情報が設定済みであること

## 必要な変数

```yaml
# 移行元設定
source_minio_host: "raspberrypi"
source_minio_ip: "192.168.1.100"  # オプション
source_minio_port: 9000

# 移行先設定
target_minio_endpoint: "https://drive.example.com"

# 移行対象
buckets_to_migrate:
  - "files"
  - "assets"
```

## 使用例

### 基本的な使用方法

```yaml
---
- hosts: truenas
  vars:
    source_minio_host: "raspberrypi"
    buckets_to_migrate: ["files", "assets"]
  roles:
    - yamisskey.appliances.migrate_minio
```

### Playbookでの使用

```bash
# 移行専用Playbook
ansible-playbook -i deploy/appliances/inventory \
  deploy/appliances/playbooks/minio-migrate.yml \
  -e "migration_source=raspberrypi"
```

## 移行プロセス

1. **前提確認** - 移行元・移行先の接続性確認
2. **エイリアス設定** - MinIO Clientの設定
3. **ウォームアップ** - 初回データ同期
4. **最終同期** - 増分データの同期
5. **検証** - ファイル数・整合性確認
6. **クリーンアップ** - 一時ファイル削除

## 制限事項

- **構築済み環境必須**: 移行先のMinIO環境が事前に構築されている必要があります
- **データ同期のみ**: バケット・IAM・CORS設定は含まれません
- **一方向のみ**: 移行元→移行先の単方向転送のみサポート

## エラー対応

### 「バケットが存在しない」エラー
```
Error: Bucket 'files' does not exist
```
**解決**: 事前に`yamisskey.appliances.minio`ロールでバケットを作成してください

### 「IAMユーザーが存在しない」エラー
```
Error: User credentials invalid
```
**解決**: 事前に`yamisskey.appliances.minio`ロールでIAMユーザーを作成してください

## 関連ロール

- `yamisskey.appliances.minio` - MinIO環境構築（前提）
- `yamisskey.appliances.core` - TrueNAS基盤準備（前提）

## 正しい実行順序

```bash
# 1. MinIO環境構築
ansible-playbook minio-deploy.yml

# 2. データ移行（このロール）
ansible-playbook minio-migrate.yml

# または一括実行
ansible-playbook minio-full.yml
```

## ライセンス

MIT
