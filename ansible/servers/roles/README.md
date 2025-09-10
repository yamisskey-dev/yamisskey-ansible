# Server Roles

このディレクトリには、サーバー管理用のAnsibleロールが含まれています。各ロールは特定のサービスや機能の設定を担当します。

## 📋 ロール一覧

### 🔧 基盤・システム
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `common` | 基本システム設定 | パッケージ管理、基本ツール、システム設定 |
| `security` | セキュリティ強化 | Fail2ban、CrowdSec、ファイアウォール、ClamAV |
| `compat` | 互換性設定 | レガシーシステム対応 |

### 🌐 Web・プロキシ
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `modsecurity-nginx` | WAF付きNginx | ModSecurity、SSL、リバースプロキシ |
| `misskey-proxy` | Misskeyプロキシ | Squidプロキシ設定 |

### 🎯 アプリケーション
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `misskey` | MisskeyのSNSサーバー | Misskey本体、PostgreSQL、Redis |
| `ai` | AI関連サービス | AI/ML サービス設定 |
| `deeplx` | 翻訳サービス | DeepL互換翻訳API |
| `searxng` | プライベート検索 | SearXNG検索エンジン |

### 💬 コミュニケーション
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `matrix` | Matrixホームサーバー | Synapse、Element |
| `jitsi` | ビデオ会議システム | Jitsi Meet |
| `stalwart` | メールサーバー | SMTP/IMAP サーバー |

### 📝 コラボレーション
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `cryptpad` | 暗号化文書共有 | CryptPad |
| `outline` | チームWiki | Outline |
| `vikunja` | タスク管理 | Vikunja |

### 💾 ストレージ・バックアップ
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `minio` | S3互換ストレージ | MinIO、IAM、CORS |
| `misskey-backup` | Misskeyバックアップ | rclone、自動バックアップ |
| `borgbackup` | 重複排除バックアップ | BorgBackup |

### 📊 監視・運用
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `monitoring` | システム監視 | Prometheus、Grafana、Blackbox |
| `uptime` | 可用性監視 | Uptime Kuma |

### 🎮 ゲーム・エンターテインメント
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `minecraft` | Minecraftサーバー | Paper/Spigot サーバー |
| `impostor` | Among Usサーバー | Impostor サーバー |
| `ctfd` | CTFプラットフォーム | CTFd |
| `lemmy` | リンクアグリゲーター | Lemmy |

### 🌍 ネットワーク・外部サービス
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `cloudflared` | Cloudflareトンネル | Cloudflare Tunnel |
| `cloudflare-warp` | CloudflareWARP | WARP設定 |
| `neo-quesdon` | 質問サービス | neo-quesdon |
| `mcaptcha` | プライベートCAPTCHA | mCaptcha |

### 🔐 認証・アクセス管理
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `zitadel` | IDaaSプラットフォーム | Zitadel |

### 🔄 データ移行・運用
| ロール | 説明 | 設定対象 |
|--------|------|----------|
| `migrate` | データ移行 | 汎用移行ツール |
| `migrate-minio` | MinIO移行 | MinIOデータ移行 |

## 📁 ロール構造

各ロールは以下の標準的なAnsible構造に従います：

```
roles/<role_name>/
├── tasks/
│   └── main.yml          # メインタスク
├── handlers/
│   └── main.yml          # ハンドラー（通知処理）
├── templates/
│   ├── config.yml.j2     # 設定ファイルテンプレート
│   └── docker-compose.yml.j2
├── vars/
│   └── main.yml          # ロール変数
├── defaults/
│   └── main.yml          # デフォルト変数
├── meta/
│   └── main.yml          # 依存関係
└── README.md             # ロール説明（個別）
```

## 🚀 ロールの使用方法

### 単体実行
```bash
# 特定のロールを含むプレイブック実行
make run PLAYBOOK=misskey
make run PLAYBOOK=security
```

### タグ指定実行
```bash
# 特定のタグのみ実行
make run PLAYBOOK=misskey TAGS=install
make run PLAYBOOK=monitoring TAGS=config
```

### ドライラン
```bash
# 実際に変更せずに確認
make check PLAYBOOK=minio
make check PLAYBOOK=security
```

## 🔧 ロール開発ガイドライン

### 設計原則
1. **冪等性**: 何度実行しても同じ結果
2. **テスト可能**: check modeで動作確認
3. **設定分離**: 環境固有設定はgroup_vars/host_varsで
4. **テンプレート活用**: 設定ファイルはJinja2テンプレート

### 必須ファイル
- `tasks/main.yml` - メインタスク
- `vars/main.yml` - ロール変数
- `README.md` - ロール説明

### 推奨構成
- Docker Composeベースの構成
- ヘルスチェック機能
- ログローテーション設定
- バックアップ対応

## 📚 主要ロール詳細

### 🎯 Misskey
- **目的**: 分散型SNSサーバー
- **コンポーネント**: Misskey、PostgreSQL、Redis
- **ポート**: 3000
- **詳細**: [misskey/README.md](misskey/README.md)

### 🛡️ ModSecurity-Nginx
- **目的**: WAF機能付きリバースプロキシ
- **機能**: SSL終端、ModSecurity、レート制限
- **ポート**: 80、443
- **詳細**: [modsecurity-nginx/README.md](modsecurity-nginx/README.md)

### 💾 MinIO
- **目的**: S3互換オブジェクトストレージ
- **機能**: バケット管理、IAM、CORS
- **ポート**: 9000、9001
- **詳細**: [minio/README.md](minio/README.md)

### 📊 Monitoring
- **目的**: システム監視とアラート
- **コンポーネント**: Prometheus、Grafana、Blackbox Exporter
- **ポート**: 9090、3001、9115
- **詳細**: [monitoring/README.md](monitoring/README.md)

## 🔗 関連ドキュメント

- [**Ansible概要**](../README.md) - Ansible設定全般
- [**プレイブック**](../playbooks/README.md) - 利用可能なプレイブック
- [**アプライアンスロール**](../../appliances/roles/README.md) - TrueNAS等のロール
- [**プロジェクト全体**](../../../README.md) - 全体概要