# 移植されたAnsibleプレイブック

このディレクトリには、本番品質のAnsibleプレイブックが含まれています。

## 📦 プレイブック一覧

### 1. system-init.yml - システム初期化
**目的**: サーバーの初期セットアップと依存関係のインストール

**機能**:
- Ansible、Docker、Tailscale、Cloudflared、Cloudflare WARP、Playitの自動インストール
- APTリポジトリとGPGキーの適切な管理
- Dockerグループへのユーザー追加とサービス有効化
- インストール状況の検証

**使用方法**:
```bash
# 統一コマンド体系での実行
make run TARGET=servers PLAYBOOK=system-init

# 特定のホストのみ対象
make run TARGET=servers PLAYBOOK=system-init LIMIT=production

# 直接Ansible実行（従来方式）
ansible-playbook -i inventory playbooks/system-init.yml --ask-become-pass
```

**注意事項**:
- 初回実行時はインターネット接続が必要
- sudoアクセスが必要

---

### 2. clone-repos.yml - リポジトリ管理
**目的**: プロジェクトに必要なGitリポジトリの一括クローン・更新

**機能**:
- 必須リポジトリと任意リポジトリの区別
- 既存リポジトリの更新
- 適切な権限設定
- 失敗したリポジトリの詳細報告

**使用方法**:
```bash
# 統一コマンド体系での実行
make run TARGET=servers PLAYBOOK=clone-repos

# カスタムリポジトリリストで実行
make run TARGET=servers PLAYBOOK=clone-repos EXTRA_VARS="repo_list=[{name: 'custom-repo', url: 'https://github.com/user/repo.git', dest: '/tmp/custom', owner: 'user', required: true}]"

# 特定のGitHub組織から
make run TARGET=servers PLAYBOOK=clone-repos EXTRA_VARS="github_org=my-org"

# 直接Ansible実行（従来方式）
ansible-playbook -i inventory playbooks/clone-repos.yml
```

**カスタマイズ**:
- `github_org`: GitHub組織名の変更
- `repo_list`: カスタムリポジトリリスト
- リポジトリの`required`フラグで必須/任意を制御

---

### 3. system-test.yml - システムテスト
**目的**: インフラストラクチャとサービスの包括的テスト

**機能**:
- インフラコンポーネント（Ansible、Docker、Tailscale）のテスト
- サービスヘルスエンドポイントのチェック
- 移行システムの検証
- ホスト固有の設定に基づくテスト

**使用方法**:
```bash
# 統一コマンド体系での実行
make run TARGET=servers PLAYBOOK=system-test

# 特定ホストのテスト
make run TARGET=servers PLAYBOOK=system-test LIMIT=balthasar

# 直接Ansible実行（従来方式）
ansible-playbook -i inventory playbooks/system-test.yml
```

**テスト項目**:
- ✅ インベントリファイルの存在
- ✅ 必須ツールの可用性
- ✅ Dockerサービスの状態
- ✅ 移行ロールの構造
- ✅ サービスヘルスエンドポイント

---

### 4. operations.yml - 運用・保守
**目的**: 日常的なサービス運用・保守作業の自動化

**機能**:
- サービス状態確認
- ヘルスチェック（ホスト設定に基づく）
- ログ確認
- サービス制御（開始/停止/再起動/更新）
- Docker環境のクリーンアップ

**使用方法**:
```bash
# 統一コマンド体系での実行

# サービス状態確認
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=status"

# 特定サービスの状態確認
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=status service=misskey"

# ヘルスチェック
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=health"

# ログ確認
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=logs service=misskey lines=100"

# サービス再起動
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=restart service=misskey"

# 全サービス再起動
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=restart service=all"

# サービス更新
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=update service=all"

# Dockerクリーンアップ
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=cleanup"

# 直接Ansible実行（従来方式）
ansible-playbook -i inventory playbooks/operations.yml -e op=status
```

**サポートする操作**:
- `status`: 状態確認
- `health`: ヘルスチェック
- `logs`: ログ表示
- `restart`: 再起動
- `stop`: 停止
- `start`: 開始
- `update`: 更新（pull + restart）
- `cleanup`: Dockerリソースクリーンアップ

## 🛠️ 高度な使用方法

### 環境別実行
```bash
# 本番環境のみ
make run TARGET=servers PLAYBOOK=system-test LIMIT=production

# 開発環境のみ
make run TARGET=servers PLAYBOOK=operations EXTRA_VARS="op=restart" LIMIT=development
```

### 並列実行
```bash
# 複数ホストで並列実行
make run TARGET=servers PLAYBOOK=clone-repos FORKS=5
```

### ドライラン
```bash
# 実際に実行せずにチェック
make run TARGET=servers PLAYBOOK=system-init CHECK=true
```

## 🔒 セキュリティ考慮事項

1. **sudo権限**: `system-init.yml`はsudo権限が必要
2. **SSH鍵**: リポジトリクローンでSSH鍵が必要な場合は事前設定が必要
3. **ネットワーク**: 外部リポジトリへのアクセスが必要
4. **機密情報**: ansible-vaultを使用して機密情報を暗号化

## 🚨 トラブルシューティング

### よくある問題

**1. GPGキーエラー**
```bash
# 手動でキーをクリア
sudo rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
# 再実行
```

**2. Dockerアクセス拒否**
```bash
# ユーザーをdockerグループに追加後、ログアウト/ログイン
sudo usermod -aG docker $USER
```

**3. リポジトリクローン失敗**
```bash
# SSH鍵の確認
ssh-add -l
# GitHub接続テスト
ssh -T git@github.com
```

### ログ確認
```bash
# 詳細ログで実行
make run TARGET=servers PLAYBOOK=system-test VERBOSE=3
```

## 📊 パフォーマンス

- **system-init.yml**: 初回実行時 5-10分
- **clone-repos.yml**: 1-3分（リポジトリサイズに依存）
- **system-test.yml**: 30秒-2分
- **operations.yml**: 10秒-5分（操作に依存）

## 🤝 貢献

改善提案やバグ報告は歓迎します。プレイブックの変更時は：

1. 事前にドライランでテスト
2. 開発環境で動作確認
3. 適切なエラーハンドリングの実装
4. ドキュメントの更新