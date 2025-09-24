# Secrets Management Migration Strategy

## 現状分析

現在、多くのロールで動的に`secrets.yml`ファイルを生成して機密情報を管理している。
- 15以上のロールで`*_secrets_file`変数を使用
- 各ロールが独立してsecrets.ymlを生成・管理
- 機密情報が平文で保存される問題

## 段階的移行戦略

### Phase 1: ハイブリッド対応 (下位互換保持)

各ロールを以下のロジックに変更：

```yaml
# 1. SOPS暗号化ファイルを優先的に検索
# 2. 従来のsecrets.ymlにフォールバック
# 3. 両方とも存在しない場合は新規生成（SOPS形式）

- name: Check for SOPS encrypted secrets
  stat:
    path: "{{ role_secrets_file | regex_replace('\\.yml$', '.sops.yml') }}"
  register: sops_secrets_stat

- name: Check for legacy secrets.yml
  stat:
    path: "{{ role_secrets_file }}"
  register: legacy_secrets_stat

- name: Load SOPS secrets when available
  community.sops.load_vars:
    file: "{{ role_secrets_file | regex_replace('\\.yml$', '.sops.yml') }}"
  when: sops_secrets_stat.stat.exists

- name: Load legacy secrets when SOPS unavailable
  include_vars:
    file: "{{ role_secrets_file }}"
  when: 
    - not sops_secrets_stat.stat.exists
    - legacy_secrets_stat.stat.exists

- name: Generate new SOPS secrets when both missing
  # 新規生成時はSOPS形式で保存
```

### Phase 2: 移行ヘルパーツール

既存のsecrets.ymlをSOPS形式に変換するツールを提供：

```bash
# 個別ファイル移行
make secrets OPERATION=migrate FILE=path/to/secrets.yml

# ロール全体移行
make secrets OPERATION=migrate-role ROLE=minio

# プロジェクト全体移行
make secrets OPERATION=migrate-all
```

### Phase 3: レガシーサポート廃止

すべての移行が完了後、legacy secrets.yml のサポートを廃止。

## 実装方針

1. **非破壊的移行**: 既存の運用を壊さない
2. **段階的導入**: ロール単位で移行可能
3. **自動化**: コマンド一つで移行完了
4. **検証**: 移行前後の整合性確認

## 移行コマンド実装

### migrate操作の追加

Makefileに以下の操作を追加：

- `migrate`: 単一ファイルをSOPS形式に変換
- `migrate-role`: ロール全体のsecretsを移行
- `migrate-all`: プロジェクト全体を移行
- `validate-migration`: 移行の整合性確認

### 自動検出機能

- 既存のsecrets.ymlファイルを自動検出
- SOPS暗号化されていないファイルを識別
- 移行が必要なファイルのリストアップ