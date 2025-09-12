# CI/CD Workflows

このディレクトリには、yamisskey-provisionプロジェクトの自動化ワークフローが含まれています。

## 📋 ワークフロー一覧

### 🔍 継続的インテグレーション (`ci.yml`)
- **トリガー**: Pull Request、mainブランチへのpush
- **目的**: コード品質とAnsible設定の検証
- **実行内容**: Linting、構文チェック、検証

### 🚀 リリース管理 (`release.yml`)
- **トリガー**: タグ作成時
- **目的**: 自動リリース作成
- **実行内容**: リリースノート生成、アーティファクト作成

## 🔍 CI ワークフロー詳細

### 実行ジョブ

#### 1. **Ansible Lint**
```yaml
- name: Run ansible-lint
  run: |
    ansible-lint ansible_collections/yamisskey/servers
    ansible-lint ansible_collections/yamisskey/appliances
```
- Ansibleプレイブックとロールの品質チェック
- ベストプラクティス遵守の確認
- 潜在的な問題の早期発見

#### 2. **YAML Lint** 
```yaml
- name: Run yamllint
  run: yamllint .
```
- YAML構文とスタイルのチェック
- インデント、改行、文字数制限の検証
- 設定ファイルの一貫性確保

#### 3. **Ansible Syntax Check**
```yaml
- name: Check ansible syntax
  run: |
    ansible-playbook --syntax-check deploy/servers/playbooks/*.yml
    ansible-playbook --syntax-check deploy/appliances/playbooks/*.yml
```
- Ansibleプレイブックの構文検証
- 実行前のエラー検出
- インポート・インクルードの整合性確認

#### 4. **Makefile Validation**
```yaml
- name: Validate Makefile
  run: |
    make help
    make list
    make list TARGET=appliances
```
- Makefile機能の基本動作確認
- 統一コマンド体系の検証
- ヘルプとリスト機能のテスト

### 検証対象

#### 📁 ディレクトリ構造
- `ansible_collections/yamisskey/servers/` - 再配布可能なサーバーコレクション
- `ansible_collections/yamisskey/appliances/` - 再配布可能なアプライアンスコレクション
- `deploy/servers/` - 実行用プレイブック/インベントリ/設定
- `deploy/appliances/` - 実行用プレイブック/インベントリ/設定
- `.yamllint.yaml` - YAML Lint設定
- `.ansible-lint` - Ansible Lint設定

#### 📝 設定ファイル
- プレイブック (`*.yml`)
- インベントリファイル
- 変数ファイル (`group_vars/`, `host_vars/`)
- Ansible設定 (`ansible.cfg`)

#### 🔧 スクリプト・ツール
- `Makefile` - 統一Ansibleラッパー
- テンプレートファイル (`*.j2`)
- 要件ファイル (`requirements.yml`)

## 🚀 リリースワークフロー詳細

### 自動リリース機能

#### トリガー条件
```yaml
on:
  push:
    tags:
      - 'v*'
```
- `v1.0.0`, `v2.1.3`等のセマンティックバージョニングタグ
- タグ作成時に自動実行

#### リリース作成
```yaml
- name: Create Release
  uses: actions/create-release@v1
  with:
    tag_name: ${{ github.ref }}
    release_name: Release ${{ github.ref }}
    body: |
      Changes in this Release
      - Added: 新機能追加
      - Changed: 既存機能の変更
      - Fixed: バグ修正
    draft: false
    prerelease: false
```

### リリース内容
- **リリースノート**: 変更履歴の自動生成
- **アーティファクト**: 設定ファイルのアーカイブ
- **タグ管理**: セマンティックバージョニング

## ⚙️ 設定ファイル

### Linting設定

#### `.yamllint.yaml`
```yaml
extends: default
rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
  comments:
    min-spaces-from-content: 1
```

#### `.ansible-lint`
```yaml
exclude_paths:
  - .cache/
  - .github/
  - backups/
  - logs/

skip_list:
  - yaml[line-length]
  - name[casing]
```

### GitHub Actions設定
```yaml
env:
  ANSIBLE_FORCE_COLOR: 1
  ANSIBLE_HOST_KEY_CHECKING: False
  PY_COLORS: 1
```

## 🔧 ローカル開発

### 事前実行推奨
```bash
# プッシュ前のローカル検証
yamllint .
ansible-lint ansible_collections/yamisskey/servers
ansible-lint ansible_collections/yamisskey/appliances
make help
make list
```

### 設定修正
```bash
# Linting エラー修正
ansible-lint --fix ansible_collections/yamisskey/servers
yamllint --format parsable . | head -20
```

## 📊 CI/CD メトリクス

### 品質指標
- **Lint通過率**: 100%目標
- **構文エラー**: 0件
- **実行時間**: 5分以内
- **成功率**: 95%以上

### パフォーマンス
- **並列実行**: マトリックス戦略活用
- **キャッシュ**: 依存関係のキャッシュ
- **最適化**: 不要なステップの除外

## 🐛 トラブルシューティング

### よくあるエラー

#### Ansible Lint エラー
```bash
# 問題: name[casing] - Task名の命名規則
# 解決: タスク名を適切にキャピタライズ

# 問題: yaml[line-length] - 行長制限
# 解決: 120文字以内に分割
```

#### YAML Lint エラー
```bash
# 問題: indentation - インデント不正
# 解決: 2スペース統一

# 問題: trailing-spaces - 末尾空白
# 解決: エディタ設定で自動削除
```

### デバッグ方法
```bash
# ローカルでCIと同等の検証
docker run --rm -v $(pwd):/data cytopia/ansible-lint:latest ansible_collections/yamisskey/servers
docker run --rm -v $(pwd):/data cytopia/yamllint:latest .
```

## 🔗 関連ドキュメント

- [**GitHub Actions公式**](https://docs.github.com/en/actions) - ワークフロー詳細
- [**Ansible Lint**](https://ansible-lint.readthedocs.io/) - Linting ルール
- [**YAML Lint**](https://yamllint.readthedocs.io/) - YAML検証
- [**プロジェクト全体**](../README.md) - 全体概要

## 📈 改善計画

### 今後の拡張
- **セキュリティスキャン**: GitLeaks、依存関係チェック
- **テスト環境**: Docker-in-Docker でのプレイブック実行テスト
- **通知機能**: Slack、Discord連携
- **メトリクス**: パフォーマンス・品質追跡

### 自動化強化
- **自動マージ**: Dependabot PR の自動統合
- **スケジュール実行**: 定期的な健全性チェック
- **マルチ環境**: 複数OS・バージョンでのテスト
