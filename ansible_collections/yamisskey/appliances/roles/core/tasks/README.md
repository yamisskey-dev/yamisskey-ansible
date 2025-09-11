# yamisskey.appliances role: core - tasks

このディレクトリは、`core` ロールのタスク定義を格納します。`setup.yml` から呼び出され、TrueNAS の基盤構成を行います。

主なタスク:
- `ensure_dataset.yml`: ZFS データセットの存在/属性の保証
- `ensure_group.yml`: グループの作成/権限設定
- `ensure_user.yml`: ユーザの作成/所属設定
- `main.yml`: 上記を統合するエントリーポイント

実行例:
- 確認: `make check PLAYBOOK=setup TARGET=appliances`
- 実行: `make run PLAYBOOK=setup TARGET=appliances`
