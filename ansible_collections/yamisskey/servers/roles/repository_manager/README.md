# Repository Manager Role

包括的なGitリポジトリ管理機能を提供するAnsibleロール。クローン、更新、バックアップ、復元、ステータス確認を統一されたインターフェースで実行できます。

## 機能

- **🔄 Clone**: Gitリポジトリのクローンとディレクトリセットアップ
- **📈 Update**: 既存リポジトリの更新（git pull）
- **💾 Backup**: リポジトリの圧縮バックアップ作成
- **🔄 Restore**: バックアップからのリポジトリ復元
- **📊 Status**: 詳細なリポジトリステータス情報表示
- **🏷️ Tag-based execution**: 機能別実行制御
- **⚙️ 設定の外部化**: デフォルト設定とカスタマイズの分離

## 使用方法

### 基本的な使用例

```yaml
# リポジトリクローン
- hosts: all
  roles:
    - repository-manager
  vars:
    repo_operation: clone
    repo_target: all

# 特定リポジトリの更新
- hosts: all
  roles:
    - repository-manager
  vars:
    repo_operation: update
    repo_target: yamisskey,yamisskey-backup

# バックアップ作成
- hosts: all
  roles:
    - repository-manager
  vars:
    repo_operation: backup
    repo_target: all

# バックアップからの復元
- hosts: all
  roles:
    - repository-manager
  vars:
    repo_operation: restore
    repo_target: yamisskey
    restore_backup_date: "20240315_143022"
```

### パラメータ

| 変数名 | デフォルト | 説明 |
|--------|-----------|------|
| `repo_operation` | `clone` | 実行する操作 (clone/update/backup/restore/status) |
| `repo_target` | `all` | 対象リポジトリ (all または特定のリポジトリ名) |
| `github_org` | `yamisskey-dev` | GitHub組織名 |
| `restore_backup_date` | - | 復元時のバックアップ日時 (YYYYMMDD_HHMMSS) |
| `backup_retention_days` | `30` | バックアップ保持期間 |
| `git_force_update` | `false` | 強制更新の有効化 |

### タグベース実行

```bash
# ディレクトリ作成のみ
ansible-playbook playbook.yml --tags "directories"

# Gitクローンのみ
ansible-playbook playbook.yml --tags "clone,git"

# バックアップ関連のみ
ansible-playbook playbook.yml --tags "backup"

# 情報表示のみ
ansible-playbook playbook.yml --tags "info"
```

## リポジトリ設定

デフォルトリポジトリ設定は `defaults/main.yml` に定義されています：

```yaml
default_repositories:
  - name: yamisskey
    url: "{{ github_org_url }}/yamisskey.git"
    dest: /var/www/misskey
    branch: master
    owner: "{{ ansible_user }}"
    become_required: true
    required: true
    description: "Main Yamisskey application"
```

### カスタムリポジトリ設定

```yaml
repositories:
  - name: custom-repo
    url: "https://github.com/example/repo.git"
    dest: /opt/custom
    branch: main
    owner: "{{ ansible_user }}"
    become_required: false
    required: true
    description: "Custom repository"
```

## 操作詳細

### Clone操作
- 存在しないリポジトリをクローン
- ディレクトリ権限の設定
- 重複クローンの回避

### Update操作
- 既存リポジトリのgit pull
- ローカル変更の検出と警告
- ブランチ整合性チェック

### Backup操作
- 各リポジトリの個別圧縮
- マニフェストファイル生成
- 古いバックアップの自動クリーンアップ
- ディスク容量チェック

### Restore操作
- バックアップからの復元
- 破壊的操作の確認プロンプト
- 復元前の自動バックアップ
- Git整合性チェック

### Status操作
- Git詳細情報表示
- リポジトリサイズ確認
- セキュリティチェック（オプション）
- ステータスレポート出力

## ディレクトリ構造

```
repository-manager/
├── tasks/
│   ├── main.yml              # メイン制御ロジック
│   ├── directory_setup.yml   # ディレクトリ作成
│   ├── repository_check.yml  # リポジトリ存在確認
│   ├── clone_repositories.yml # クローン実行
│   ├── update_repositories.yml # 更新実行
│   ├── backup_repositories.yml # バックアップ実行
│   ├── restore_repositories.yml # 復元実行
│   ├── status_check.yml      # ステータス確認
│   └── verification.yml      # 最終検証
├── defaults/main.yml         # デフォルト設定
└── README.md                # このファイル
```

## 依存関係

- Ansible 2.9+
- Git 2.0+
- 対象ホストでのgit コマンド利用可能

## セキュリティ考慮事項

- SSH鍵認証の推奨
- パスワード認証情報の環境変数での管理
- バックアップディレクトリのアクセス権限制限
- 復元操作時の確認プロンプト

## トラブルシューティング

### よくある問題

1. **SSH鍵エラー**
   ```bash
   # SSH鍵の確認
   ssh-add -l
   ```

2. **権限エラー**
   ```bash
   # become設定の確認
   become_required: true
   ```

3. **ディスク容量不足**
   ```bash
   # バックアップ前の容量確認が自動実行
   ```

## 使用例

```bash
# 全リポジトリクローン
ansible-playbook -i inventory clone-repos.yml

# 特定リポジトリ更新
ansible-playbook -i inventory clone-repos.yml -e "repo_operation=update repo_target=yamisskey"

# バックアップ作成
ansible-playbook -i inventory clone-repos.yml -e "repo_operation=backup"

# ステータス確認
ansible-playbook -i inventory clone-repos.yml -e "repo_operation=status"
```

## ライセンス

このロールは既存のyamisskey-provisionプロジェクトのライセンスに従います。