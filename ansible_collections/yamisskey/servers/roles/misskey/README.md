# yamisskey.servers role: misskey

分散型SNSプラットフォーム「Misskey」の展開・管理を行うAnsibleロールです。

## 📋 概要

このロールは以下の機能を提供します：

- **Misskeyアプリケーション**: yamisskey（カスタムMisskeyフォーク）の自動展開
- **データベース**: PostgreSQL設定とデータベース初期化
- **キャッシュ**: Redis設定と連携
- **プロキシ連携**: Squidプロキシとの統合
- **設定管理**: 環境別設定ファイルの自動生成

## 🏗️ アーキテクチャ

```
Internet → Nginx(ModSecurity) → Misskey(Node.js) → PostgreSQL
                              ↘ Redis (Cache)
                              ↘ Squid (Proxy)
                              ↘ MinIO (Object Storage)
```

## 📁 ロール構造

```
misskey/
├── tasks/
│   └── main.yml                    # メインデプロイメントタスク
├── handlers/
│   └── main.yml                    # サービス再起動等のハンドラー
├── templates/
│   ├── docker_example.env.j2       # 環境変数テンプレート
│   ├── docker_example.yml.j2       # Docker設定テンプレート
│   ├── misskey_docker-compose.yml.j2 # Docker Compose設定
│   └── misskey_postgresql.conf.j2   # PostgreSQL設定
├── vars/
│   └── main.yml                    # ロール変数定義
├── meta/
│   └── main.yml                    # 依存関係定義
└── README.md                       # このドキュメント
```

## ⚙️ 設定変数

### アプリケーション設定
```yaml
# GitHub リポジトリ設定
misskey_repo: 'https://github.com/{{ github_org }}/yamisskey.git'
misskey_branch: master
misskey_tag: latest
misskey_dir: '/var/www/misskey'

# サービス設定
misskey_port: '{{ host_services.balthasar.misskey }}'  # ポート番号
misskey_proxy: 'http://127.0.0.1:{{ host_services.linode_prox.squid }}'
```

### データベース設定
```yaml
# PostgreSQL設定
misskey_db_name: 'example_misskey_db'
misskey_db_user: 'example_misskey_user' 
misskey_db_pass: 'example_misskey_pass'
```

### 環境固有設定
group_vars/all.yml での設定例：
```yaml
# ホスト設定
host_services:
  balthasar:
    misskey: 3000
  linode_prox:
    squid: 3128

# GitHub組織
github_org: 'yamisskey-dev'

# ドメイン設定
misskey_domain: 'yami.ski'
```

## 🚀 使用方法

### 基本実行
```bash
# Misskeyプレイブック実行
make run PLAYBOOK=misskey

# ドライラン（変更内容確認）
make check PLAYBOOK=misskey

# 特定のタグのみ実行
make run PLAYBOOK=misskey TAGS=install
make run PLAYBOOK=misskey TAGS=config
```

### インストールフロー
```bash
# 1. 基盤環境構築
make run PLAYBOOK=common
make run PLAYBOOK=security

# 2. データベース・キャッシュ準備
# (PostgreSQL・Redisはcommonロールに含まれる)

# 3. Webサーバー・プロキシ設定
make run PLAYBOOK=modsecurity-nginx
make run PLAYBOOK=misskey-proxy

# 4. Misskey本体インストール
make run PLAYBOOK=misskey

# 5. ストレージ設定（オプション）
make run PLAYBOOK=minio
```

## 🔧 テンプレートファイル

### Docker Compose設定 (`misskey_docker-compose.yml.j2`)
- Misskeyアプリケーションコンテナ設定
- PostgreSQL・Redis連携設定
- 環境変数・ボリュームマウント設定
- ネットワーク・ポートマッピング

### 環境設定 (`docker_example.env.j2`)
- データベース接続情報
- Redis接続設定
- MinIO（オブジェクトストレージ）設定
- セキュリティ関連変数

### PostgreSQL設定 (`misskey_postgresql.conf.j2`)
- Misskey向け最適化設定
- 接続・メモリ・ログ設定
- パフォーマンスチューニング

## 📊 依存関係

### 前提ロール
- `common` - 基本システム設定、PostgreSQL・Redis
- `modsecurity-nginx` - リバースプロキシ設定
- `misskey-proxy` (オプション) - プロキシ設定

### 関連サービス
- **PostgreSQL**: メインデータベース
- **Redis**: セッション・キャッシュストレージ  
- **Nginx**: リバースプロキシ・SSL終端
- **MinIO**: メディアファイルストレージ（オプション）

## 🔒 セキュリティ設定

### 環境変数による秘匿情報管理
```yaml
# group_vars/vault.yml (Ansible Vault暗号化推奨)
vault_misskey_db_pass: "secure_database_password"
vault_misskey_secret_key: "application_secret_key"
vault_minio_access_key: "s3_access_key"
vault_minio_secret_key: "s3_secret_key"
```

### 接続セキュリティ
- プロキシ経由の外部通信
- データベース接続のSSL化
- セッション管理の強化

## 🎯 実行例

### 開発環境セットアップ
```bash
# 最小構成でのインストール
make run PLAYBOOK=common
make run PLAYBOOK=misskey TAGS=install,config

# 開発用設定での実行
MISSKEY_ENV=development make run PLAYBOOK=misskey
```

### 本番環境デプロイメント
```bash
# フルスタックデプロイメント
make deploy PLAYBOOKS='common security modsecurity-nginx misskey-proxy misskey minio'

# 段階的デプロイメント
make run PLAYBOOK=common
make check PLAYBOOK=misskey    # 確認
make run PLAYBOOK=misskey      # 実行
```

### メンテナンス作業
```bash
# 設定ファイルのみ更新
make run PLAYBOOK=misskey TAGS=config

# サービス再起動
make run PLAYBOOK=misskey TAGS=restart

# アプリケーション更新
make run PLAYBOOK=misskey TAGS=update
```

## 🐛 トラブルシューティング

### よくある問題

#### データベース接続エラー
```bash
# PostgreSQL接続確認
sudo -u postgres psql -c "\l"

# Misskeyデータベース確認
sudo -u postgres psql example_misskey_db -c "SELECT version();"

# 設定ファイル確認
cat /var/www/misskey/.env
```

#### Redis接続エラー
```bash
# Redis動作確認
redis-cli ping

# Redis設定確認
sudo systemctl status redis
```

#### ポート競合
```bash
# ポート使用状況確認
sudo netstat -tlnp | grep :3000

# Misskeyプロセス確認
ps aux | grep misskey
```

### ログ確認
```bash
# Docker Composeログ
cd /var/www/misskey && docker-compose logs -f

# Nginx アクセスログ
sudo tail -f /var/log/nginx/access.log

# システムログ
sudo journalctl -u docker -f
```

## 📈 パフォーマンス最適化

### PostgreSQL チューニング
- `shared_buffers`: メモリ使用量最適化
- `max_connections`: 同時接続数調整
- `work_mem`: ソート・ハッシュ操作メモリ

### Redis チューニング
- `maxmemory`: キャッシュサイズ調整
- `maxmemory-policy`: 削除ポリシー設定

### アプリケーション最適化
- Node.js ヒープサイズ調整
- ワーカープロセス数最適化

## 🔗 関連ドキュメント

- [**Misskeyプロジェクト公式**](https://misskey.dev/) - Misskey概要・機能
- [**yamisskey リポジトリ**](https://github.com/yamisskey-dev/yamisskey) - カスタムフォーク詳細
- [**サーバーロール一覧**](../README.md) - 他のロール詳細
- [**プロジェクト全体**](../../../../README.md) - 全体構成・使用方法

## 🔄 バックアップ・復旧

### データバックアップ
```bash
# データベースバックアップ
sudo -u postgres pg_dump example_misskey_db > misskey_backup.sql

# メディアファイルバックアップ（MinIO使用時）
make run PLAYBOOK=misskey-backup
```

### 復旧手順
```bash
# データベース復旧
sudo -u postgres psql example_misskey_db < misskey_backup.sql

# アプリケーション再起動
cd /var/www/misskey && docker-compose restart