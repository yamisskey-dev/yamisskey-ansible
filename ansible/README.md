# Ansible Infrastructure Management

このディレクトリには、yamisskey-provisionプロジェクトのAnsible設定とプレイブックが含まれています。

## 📁 ディレクトリ構造

```
ansible/
├── servers/          # サーバー管理用Ansible設定
│   ├── playbooks/    # サーバー用プレイブック
│   ├── roles/        # サーバー用ロール
│   └── inventory     # サーバーインベントリ（make inventoryで作成）
└── appliances/       # アプライアンス管理用Ansible設定
    ├── playbooks/    # TrueNAS等アプライアンス用プレイブック
    ├── roles/        # アプライアンス用ロール
    └── inventory     # アプライアンスインベントリ（make inventory TARGET=appliancesで作成）
```

## 🎯 2つのターゲット環境

### Servers (`TARGET=servers`)
- **用途**: 一般的なLinuxサーバーの管理
- **対象**: Ubuntu/Debian系サーバー
- **サービス**: Misskey、MinIO、監視、セキュリティ等
- **実行**: `make run PLAYBOOK=<name>`

### Appliances (`TARGET=appliances`)
- **用途**: TrueNAS等のストレージアプライアンス管理
- **対象**: TrueNAS SCALE
- **サービス**: MinIO移行、ストレージ設定等
- **実行**: `make run PLAYBOOK=<name> TARGET=appliances`

## 🚀 クイックスタート

### 1. 環境セットアップ
```bash
# Ansible等のツールをインストール
make install

# サーバー用インベントリを作成
make inventory

# アプライアンス用インベントリを作成
make inventory TARGET=appliances
```

### 2. 基本的な使用方法
```bash
# サーバー向けプレイブック実行
make run PLAYBOOK=common
make run PLAYBOOK=security

# アプライアンス向けプレイブック実行
make run PLAYBOOK=setup TARGET=appliances
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances

# 利用可能なプレイブック一覧
make list                      # サーバー用
make list TARGET=appliances    # アプライアンス用
```

## 📋 利用可能なプレイブック

### サーバー向け（35種類）
詳細は [`servers/playbooks/README.md`](servers/playbooks/README.md) を参照してください。

**主要なプレイブック:**
- `common` - 基本システム設定
- `security` - セキュリティ強化
- `misskey` - Misskey SNSサーバー
- `minio` - S3互換オブジェクトストレージ
- `monitoring` - システム監視

### アプライアンス向け（5種類）
詳細は [`appliances/README.md`](appliances/README.md) を参照してください。

**主要なプレイブック:**
- `setup` - TrueNAS初期設定
- `migrate-minio-truenas` - TrueNAS上でのMinIO設定
- `migrate-minio-phase-a` - MinIO移行フェーズA

## ⚙️ 設定ファイル

### インベントリファイル
- `servers/inventory` - サーバー一覧（make inventoryで作成）
- `appliances/inventory` - アプライアンス一覧（make inventory TARGET=appliancesで作成）

### グループ変数
- `servers/group_vars/all.yml` - サーバー共通変数
- `appliances/group_vars/all.yml` - アプライアンス共通変数

### Ansible設定
- `servers/ansible.cfg` - サーバー用Ansible設定
- `appliances/ansible.cfg` - アプライアンス用Ansible設定

## 🔧 高度な使用方法

### パラメータ指定
```bash
# 特定のホストに限定
make run PLAYBOOK=security LIMIT=local

# 特定のタグのみ実行
make run PLAYBOOK=misskey TAGS=install,config

# ドライラン実行
make check PLAYBOOK=common
```

### 複数プレイブック実行
```bash
# サーバー向けシーケンシャル実行
make deploy PLAYBOOKS='common security monitoring'

# アプライアンス向けシーケンシャル実行
make deploy PLAYBOOKS='setup migrate-minio-phase-a' TARGET=appliances
```

## 📚 関連ドキュメント

- [**プロジェクトルート README**](../README.md) - 全体概要と使用方法
- [**サーバー管理**](servers/README.md) - サーバー向け詳細説明
- [**アプライアンス管理**](appliances/README.md) - アプライアンス向け詳細説明
- [**サーバーロール**](servers/roles/) - 各ロールの詳細
- [**CI/CD**](../.github/README.md) - 自動化ワークフロー