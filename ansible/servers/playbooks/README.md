# 移植されたAnsibleプレイブック

このディレクトリには、Makefileから移植された本番品質のAnsibleプレイブックが含まれています。

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
# 基本的な実行
ansible-playbook -i inventory playbooks/system-init.yml --ask-become-pass

# 特定のホストのみ対象
ansible-playbook -i inventory playbooks/system-init.yml --limit production --ask-become-pass
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
# 全リポジトリのクローン
ansible-playbook -i inventory playbooks/clone-repos.yml

# カスタムリポジトリリストで実行
ansible-playbook -i inventory playbooks/clone-repos.yml \
  -e "repo_list=[{name: 'custom-repo', url: 'https://github.com/user/repo.git', dest: '/tmp/custom', owner: 'user', required: true}]"

# 特定のGitHub組織から
ansible-playbook -i inventory playbooks/clone-repos.yml -e github_org=my-org
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
# 全体テストの実行
ansible-playbook -i inventory playbooks/system-test.yml

# 特定ホストのテスト
ansible-playbook -i inventory playbooks/system-test.yml --limit balthasar
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
# サービス状態確認
ansible-playbook -i inventory playbooks/operations.yml -e op=status

# 特定サービスの状態確認
ansible-playbook -i inventory playbooks/operations.yml -e op=status -e service=misskey

# ヘルスチェック
ansible-playbook -i inventory playbooks/operations.yml -e op=health

# ログ確認
ansible-playbook -i inventory playbooks/operations.yml -e op=logs -e service=misskey -e lines=100

# サービス再起動
ansible-playbook -i inventory playbooks/operations.yml -e op=restart -e service=misskey

# 全サービス再起動
ansible-playbook -i inventory playbooks/operations.yml -e op=restart -e service=all

# サービス更新
ansible-playbook -i inventory playbooks/operations.yml -e op=update -e service=all

# Dockerクリーンアップ
ansible-playbook -i inventory playbooks/operations.yml -e op=cleanup
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
ansible-playbook -i inventory playbooks/system-test.yml --limit production

# 開発環境のみ
ansible-playbook -i inventory playbooks/operations.yml -e op=restart --limit development
```

### 並列実行
```bash
# 複数ホストで並列実行
ansible-playbook -i inventory playbooks/clone-repos.yml --forks 5
```

### ドライラン
```bash
# 実際に実行せずにチェック
ansible-playbook -i inventory playbooks/system-init.yml --check --diff
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
ansible-playbook -i inventory playbooks/system-test.yml -vvv
```

## 🔄 Makefileとの関係

これらのプレイブックは以下のMakefileターゲットを置き換えます：

- `make sv-install` → `ansible-playbook playbooks/system-init.yml`
- `make sv-clone` → `ansible-playbook playbooks/clone-repos.yml`
- `make sv-test` → `ansible-playbook playbooks/system-test.yml`
- 運用機能 → `ansible-playbook playbooks/operations.yml`

Makefileは動的インベントリ生成とAnsibleプレイブック実行のラッパーとして引き続き使用されます。

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