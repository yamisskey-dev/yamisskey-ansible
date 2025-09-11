# yamisskey.appliances Collection

TrueNAS などのアプライアンス系を扱う Ansible コレクションです。実行用の playbook/inventory はレポジトリ直下の `deploy/` に分離しています。

## 構成（モノレポ）
- `ansible_collections/yamisskey/appliances/`
  - `roles/` 再配布対象のロール群
  - `plugins/` プラグイン（必要に応じて）
  - `meta/runtime.yml` 対応 Ansible などの宣言
  - `tests/` ansible-test 用（sanity/integration）
- `deploy/appliances/`
  - `ansible.cfg` 実行用設定（roles_path はコレクションを指す）
  - `inventory` 運用向けインベントリ
  - `playbooks/` 運用用プレイブック

## 🚀 Install & Use (Quick)
```bash
# From Galaxy
ansible-galaxy collection install yamisskey.appliances

# Or from local tarball
ansible-galaxy collection install dist/appliances/yamisskey-appliances-*.tar.gz
```

## 実行
```bash
# 一覧
make list TARGET=appliances

# ドライラン
make check PLAYBOOK=setup TARGET=appliances

# 実行
make run PLAYBOOK=setup TARGET=appliances
```

## テスト
### Sanity
```bash
# コレクション直下で sanity
cd ansible_collections/yamisskey/appliances
ansible-test sanity --python 3.11 -v
```

### Integration (smoke)
最小の smoke テストを用意しています。
```bash
ansible-test integration -v --docker default --python 3.11 \
  --targets smoke
```

## ビルド
```bash
# コレクション単体のビルド
cd ansible_collections/yamisskey/appliances
ansible-galaxy collection build --force

# ルートのヘルパー
make build  # 両コレクション分を dist/ に生成
```

## メモ
- 運用物（inventory/group_vars/host_vars/playbooks）は `deploy/` 側で管理します。
- コレクションは roles/plugins/meta/tests のみを含め、再配布可能な最小構成に保ちます。
