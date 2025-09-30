# yamisskey.appliances role: core

TrueNAS SCALE環境の基盤設定を担当するAnsibleロールです。API駆動による冪等的なシステム設定、データセット管理、ユーザー・グループ管理、設定バックアップを提供します。

## 📋 概要

このロールは、TrueNAS SCALE 25.04環境において以下の基盤機能を提供します：

- **データセット管理**: ZFSデータセットの自動作成と設定
- **権限管理**: POSIX/ACL権限の適切な設定
- **ユーザー・グループ管理**: システムユーザーとグループの冪等的作成
- **システム検証**: ミドルウェア接続とシステム情報確認
- **設定バックアップ**: TrueNAS設定データベースの自動バックアップ

## 🔧 主要機能

### 1. システム検証
- TrueNAS ミドルウェア（`midclt`）接続確認
- システム情報取得と検証
- API応答性チェック

### 2. データセット管理
ZFSデータセットの作成と最適化設定：

```yaml
truenas_datasets:
  - name: "apps/minio"
    compression: "lz4"
    atime: false
    recordsize: "1M"
    acl: "POSIX"
    uid: 1801
    gid: 1800
    mode: "0755"
```

**サポートする設定**:
- **compression**: `lz4`, `gzip`, `zstd`, `off`
- **recordsize**: `4K` ～ `1M` (パフォーマンス最適化)
- **atime**: アクセス時刻記録の有効/無効
- **acl**: `POSIX` または `NFSv4`

### 3. ユーザー・グループ管理

**グループ作成**:
```yaml
truenas_groups:
  - name: "apps"
    gid: 1800
```

**ユーザー作成**:
```yaml
truenas_users:
  - name: "minio"
    uid: 1801
    gid: 1800
    home: "/nonexistent"
    description: "MinIO Service Account"
```

### 4. 権限設定
- POSIX ACLの適切な処理
- ファイルシステム権限の冪等的設定
- セキュアな権限継承

### 5. 設定バックアップ
- TrueNAS設定データベースの自動バックアップ
- タイムスタンプ付きファイル生成
- 指定ディレクトリへの安全な保存

## ⚙️ 設定変数

### 必須変数

```yaml
# TrueNAS接続設定
truenas_host: "192.168.1.100"
truenas_pool_name: "tank"
truenas_backup_path: "/mnt/tank/backups/config"

# データセット設定
truenas_datasets:
  - name: "apps/minio"
    compression: "lz4"
    atime: false
    recordsize: "1M"
    acl: "POSIX"
    uid: 1801
    gid: 1800
    mode: "0755"
```

### オプション変数

```yaml
# グループ設定（オプション）
truenas_groups:
  - name: "apps"
    gid: 1800

# ユーザー設定（オプション）
truenas_users:
  - name: "minio"
    uid: 1801
    gid: 1800
    home: "/nonexistent"
    description: "MinIO Service Account"
    password: ""  # パスワードなしアカウント
```

## 🚀 使用方法

### 基本的な使用

```bash
# 統一コマンド体系
make run TARGET=appliances PLAYBOOK=setup

# 直接ロール実行
ansible-playbook -i inventory playbooks/setup.yml
```

### 高度な使用

```bash
# 特定データセットのみ
make run TARGET=appliances PLAYBOOK=setup TAGS=datasets

# ドライラン
make run TARGET=appliances PLAYBOOK=setup CHECK=true

# カスタム設定
make run TARGET=appliances PLAYBOOK=setup EXTRA_VARS="truenas_pool_name=storage"
```

## 📁 ディレクトリ構造

```
ansible_collections/yamisskey/appliances/roles/core/
├── tasks/
│   ├── main.yml              # メインタスク
│   ├── ensure_dataset.yml    # データセット作成
│   ├── ensure_group.yml      # グループ作成
│   ├── ensure_user.yml       # ユーザー作成
│   └── ensure_snapshot.yml   # スナップショット管理
└── README.md                 # このファイル
```

## 🛡️ セキュリティ考慮事項

### 1. API認証
```yaml
# 推奨: SOPS で暗号化
truenas_api_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  636361653...
```

### 2. 権限最小化
- 必要最小限のUID/GIDを使用
- サービスアカウントにはシェルアクセスを与えない
- ホームディレクトリは `/nonexistent` を推奨

### 3. データセット分離
```yaml
# アプリケーション別データセット分離
truenas_datasets:
  - name: "apps/minio"       # MinIO専用
  - name: "apps/postgres"    # PostgreSQL専用
  - name: "backups/system"   # システムバックアップ
```

## 🔍 トラブルシューティング

### よくある問題

**1. midclt接続失敗**
```bash
# 手動確認
ssh root@truenas.local
midclt call system.info

# サービス再起動
systemctl restart middlewared
```

**2. データセット作成失敗**
```bash
# プール状態確認
zpool status

# 権限確認
zfs allow
```

**3. ユーザー作成失敗**
```bash
# 既存ユーザー確認
midclt call user.query

# UID競合確認
id 1801
```

### デバッグ方法

```bash
# 詳細ログで実行
make run TARGET=appliances PLAYBOOK=setup VERBOSE=3

# 特定タスクのみ実行
make run TARGET=appliances PLAYBOOK=setup TAGS=users

# 設定確認
ansible-inventory -i inventory --list
```

## 📊 パフォーマンス最適化

### ZFS設定推奨値

```yaml
# MinIO用データセット
truenas_datasets:
  - name: "apps/minio"
    recordsize: "1M"      # 大きなファイル用
    compression: "lz4"    # 高速圧縮
    atime: false          # パフォーマンス向上
    sync: "standard"      # 書き込み最適化
```

### メモリ使用量
- 軽量なAPI呼び出しのみ
- 大量データの同期処理なし
- メモリ使用量: < 100MB

## 🔗 関連ドキュメント

- [TrueNAS SCALE API](https://www.truenas.com/docs/scale/scaletutorials/apps/usingmidclt/)
- [ZFS Dataset Management](https://openzfs.github.io/openzfs-docs/)
- [ansible_collections/yamisskey/appliances/roles/apps/README.md](../apps/README.md)
- [deploy/appliances/playbooks/README.md](../../../../deploy/appliances/playbooks)

## 🤝 貢献

改善提案は歓迎します：

1. **TrueNAS API新機能の活用**
2. **ZFS設定の最適化**
3. **エラーハンドリングの改善**
4. **セキュリティ強化**

変更時は必ずテスト環境で検証してください。
