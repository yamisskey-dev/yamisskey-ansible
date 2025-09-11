# deploy/servers/group_vars

このディレクトリは、サーバ向けの Ansible グループ変数 (`group_vars`) を格納します。

- 目的: グループ単位で共有される設定値（パッケージ、サービス設定など）を定義します。
- 形式: `*.yml`（YAML）。ファイル名がグループ名になります（例: `all.yml`）。

使い方:
- 変数を更新後、該当プレイブックを実行します。
  - 確認実行: `make check PLAYBOOK=common`
  - 本番実行: `make run PLAYBOOK=common`

参考:
- ルートの `README.md`（Make コマンド集）
- `ansible_collections/yamisskey/servers/README.md`
