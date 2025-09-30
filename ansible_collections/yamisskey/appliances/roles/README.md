# Appliance Roles

このディレクトリには、アプライアンス管理用のAnsibleロールが含まれています。主にTrueNAS SCALE等のストレージアプライアンスの設定・管理を行います。

## 📋 ロール一覧

### 🔧 基盤・コア機能
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `core` | TrueNAS基盤機能 | データセット、ユーザー、グループ、スナップショット |

## 📁 ロール構造

アプライアンス用ロールは以下の構造に従います：

```
roles/<role_name>/
├── tasks/
│   ├── main.yml              # メインタスク
│   ├── ensure_dataset.yml    # データセット作成
│   ├── ensure_user.yml       # ユーザー管理
│   ├── ensure_group.yml      # グループ管理
│   └── ensure_snapshot.yml   # スナップショット管理
├── defaults/
│   └── main.yml              # デフォルト変数
├── vars/
│   └── main.yml              # ロール変数
└── README.md                 # ロール説明
```

## 🎯 Core ロール詳細

### 機能概要
- **データセット管理**: ZFSデータセットの作成・設定
- **ユーザー管理**: アプライアンス用ユーザーの作成・管理
- **グループ管理**: アクセス制御用グループの管理
- **スナップショット管理**: 自動スナップショット設定

### 主要タスク

#### データセット作成 (`ensure_dataset.yml`)
```yaml
# ZFSデータセットの作成
- name: Ensure dataset exists
  uri:
    url: "{{ truenas_base_url }}/api/v2.0/pool/dataset"
    method: POST
    headers:
      Authorization: "Bearer {{ api_key }}"
    body_format: json
    body:
      name: "{{ dataset_name }}"
      pool: "{{ pool_name }}"
```

#### ユーザー管理 (`ensure_user.yml`)
```yaml
# サービス用ユーザーの作成
- name: Create service user
  uri:
    url: "{{ truenas_base_url }}/api/v2.0/user"
    method: POST
    headers:
      Authorization: "Bearer {{ api_key }}"
    body_format: json
    body:
      username: "{{ service_user }}"
      full_name: "{{ service_description }}"
```

## 🚀 使用方法

### 基本実行
```bash
# TrueNAS初期設定
make run PLAYBOOK=setup TARGET=appliances

# MinIO関連設定
make run PLAYBOOK=migrate-minio-truenas TARGET=appliances
```

### パラメータ指定
```bash
# 特定のタスクのみ実行
make run PLAYBOOK=setup TARGET=appliances TAGS=dataset

# 特定のホストに限定
make run PLAYBOOK=setup TARGET=appliances LIMIT=truenas.local
```

### ドライラン
```bash
# 実際に変更せずに確認
make check PLAYBOOK=setup TARGET=appliances
```

## ⚙️ 設定

### 変数設定
アプライアンス固有の設定は以下で管理します：

```yaml
# deploy/appliances/group_vars/all.yml
truenas_base_url: "https://truenas.local"
pool_name: "main-pool"

# サービス設定
minio_user: "minio"
minio_group: "minio"
minio_dataset: "main-pool/minio"
```

### ホスト固有設定
```yaml
# deploy/appliances/host_vars/truenas.yml
ansible_host: "truenas.local"
ansible_user: "root"
ansible_python_interpreter: "/usr/bin/python3"
```

## 🔧 開発ガイドライン

### TrueNAS API使用原則
1. **認証**: Bearer Tokenによる認証
2. **冪等性**: 既存リソースのチェック→作成の流れ
3. **エラーハンドリング**: APIエラーの適切な処理
4. **バリデーション**: 作成前の事前チェック

### 推奨パターン
```yaml
# リソース存在チェック
- name: Check if dataset exists
  uri:
    url: "{{ truenas_base_url }}/api/v2.0/pool/dataset/id/{{ dataset_path }}"
    method: GET
    headers:
      Authorization: "Bearer {{ api_key }}"
    status_code: [200, 404]
  register: dataset_check

# 条件付き作成
- name: Create dataset if not exists
  uri:
    url: "{{ truenas_base_url }}/api/v2.0/pool/dataset"
    method: POST
    headers:
      Authorization: "Bearer {{ api_key }}"
    body_format: json
    body:
      name: "{{ dataset_name }}"
      pool: "{{ pool_name }}"
  when: dataset_check.status == 404
```

## 📚 TrueNAS API リファレンス

### 主要エンドポイント
- **データセット**: `/api/v2.0/pool/dataset`
- **ユーザー**: `/api/v2.0/user`
- **グループ**: `/api/v2.0/group`
- **サービス**: `/api/v2.0/service`
- **共有**: `/api/v2.0/sharing`

### 認証
```bash
# APIキーの取得
curl -X POST "https://truenas.local/api/v2.0/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "root", "password": "password"}'
```

## 🔗 関連ドキュメント

- [**Ansible概要**](../README.md) - Ansible設定全般
- [**アプライアンスプレイブック**](../playbooks/) - 利用可能なプレイブック
- [**サーバーロール**](../../servers/roles/README.md) - サーバー管理ロール
- [**プロジェクト全体**](../../../README.md) - 全体概要

## 🎯 実行例

### 完全セットアップ
```bash
# 1. TrueNAS基本設定
make run PLAYBOOK=setup TARGET=appliances

# 2. MinIO設定とデータ移行
make run PLAYBOOK=migrate-minio-truenas TARGET=appliances

# 3. 移行フェーズA実行
make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances
```

### トラブルシューティング
```bash
# 設定確認（ドライラン）
make check PLAYBOOK=setup TARGET=appliances

# ログ確認
make logs

# インベントリ確認
cat deploy/appliances/inventory
