# yamisskey.appliances

TrueNAS Scale およびその他のアプライアンス機器向けのAnsibleコレクション

## 🏗️ ロール構造（改善後）

### 責任分離された3つのロール

```
roles/
├── core/           # TrueNAS基盤管理
├── minio/          # MinIO構築専用
└── migrate_minio/  # MinIO移行専用
```

#### **`yamisskey.appliances.core`**
- **責任**: TrueNAS Scale基盤の準備
- **機能**: ZFSデータセット、ユーザー管理、システム設定

#### **`yamisskey.appliances.minio`** ✨ 新規作成
- **責任**: MinIO環境の構築のみ
- **機能**: Docker Compose、Cloudflare Tunnel、Nginx設定

#### **`yamisskey.appliances.migrate_minio`**
- **責任**: MinIOデータ移行のみ
- **機能**: データ同期、IAM/CORS移行、移行検証

### 非推奨ロール

#### **`yamisskey.appliances.apps`** ⚠️ 機能移行済み
- MinIO固有機能は [`minio`](roles/minio) ロールに移行済み
- 汎用アプリ管理ロールとして今後活用予定

## 🚀 使用方法

### 1. MinIO構築のみ

```bash
# TrueNAS上にMinIOを構築
ansible-playbook -i deploy/appliances/inventory \
  deploy/appliances/playbooks/minio-deploy.yml
```

### 2. MinIO移行のみ

```bash
# 既存MinIOからTrueNAS MinIOへデータ移行
ansible-playbook -i deploy/appliances/inventory \
  deploy/appliances/playbooks/minio-migrate.yml \
  -e "migration_source=raspberrypi"
```

### 3. フルワークフロー（構築 + 移行）

```bash
# 構築と移行を一括実行
ansible-playbook -i deploy/appliances/inventory \
  deploy/appliances/playbooks/minio-full.yml \
  -e "migration_source=raspberrypi"
```

### 4. 構築のみ実行（移行スキップ）

```bash
# 移行を無効化して構築のみ
ansible-playbook -i deploy/appliances/inventory \
  deploy/appliances/playbooks/minio-full.yml \
  -e "enable_migration=false"
```

## 📋 Playbook一覧

| Playbook | 責任 | 使用ケース |
|----------|------|-----------|
| [`minio-deploy.yml`](deploy/appliances/playbooks/minio-deploy.yml) | MinIO構築のみ | 新規環境構築 |
| [`minio-migrate.yml`](deploy/appliances/playbooks/minio-migrate.yml) | MinIO移行のみ | 既存環境からの移行 |
| [`minio-full.yml`](deploy/appliances/playbooks/minio-full.yml) | 構築 + 移行 | ワンストップデプロイ |
| [`truenas-minio-deploy-and-migrate.yml`](deploy/appliances/playbooks/truenas-minio-deploy-and-migrate.yml) | 既存互換 | 後方互換性維持 |

## ⚙️ 必要な変数

### TrueNAS基盤
```yaml
truenas_pool_name: "tank"
truenas_api_key: "{{ truenas_api_key }}"
```

### MinIO設定
```yaml
truenas_minio_domain: "drive.example.com"
```

### 移行設定（移行時のみ）
```yaml
migration_source: "raspberrypi"  # 移行元ホスト名
source_minio_ip: "192.168.1.100"  # オプション
```

## 🔄 移行シナリオ

### raspberrypi → joseph (TrueNAS Scale)

```bash
# 段階的移行
ansible-playbook minio-deploy.yml      # 1. TrueNAS環境構築
ansible-playbook minio-migrate.yml     # 2. データ移行

# または一括移行
ansible-playbook minio-full.yml -e "migration_source=raspberrypi"
```

## 🎯 改善点

### Before（問題あり）
```yaml
roles:
  - yamisskey.appliances.apps  # MinIO + 汎用機能が混在
```

### After（改善後）
```yaml
roles:
  - yamisskey.appliances.core     # 基盤準備
  - yamisskey.appliances.minio    # MinIO構築
  # 移行は別Playbookで実行
```

## 📁 ディレクトリ構造

```
ansible_collections/yamisskey/appliances/
├── roles/
│   ├── core/           # TrueNAS基盤
│   ├── minio/          # MinIO構築（新規）
│   ├── migrate_minio/  # MinIO移行
│   └── apps/           # 汎用アプリ（MinIO機能除去済み）
└── deploy/appliances/
    └── playbooks/
        ├── minio-deploy.yml    # 構築専用（新規）
        ├── minio-migrate.yml   # 移行専用（新規）
        └── minio-full.yml      # フルワークフロー（新規）
```

## 🏷️ タグ使用例

```bash
# 基盤のみ
ansible-playbook minio-full.yml --tags core

# MinIOデプロイのみ
ansible-playbook minio-full.yml --tags minio

# 移行のみ
ansible-playbook minio-full.yml --tags migration
```

## 📝 ライセンス

MIT
