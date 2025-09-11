# deploy/servers/host_vars

このディレクトリは、サーバ向けの Ansible ホスト変数 (`host_vars`) を格納します。

- 目的: 各サーバに固有の設定値（ポート、パス、シークレット参照など）を定義します。
- 形式: `*.yml`（YAML）。ファイル名がホスト名になります。

使い方:
- 変数を更新後、該当プレイブックを実行します。
  - 確認実行: `make check PLAYBOOK=security`
  - 本番実行: `make run PLAYBOOK=security`

注意:
- シークレットは Ansible Vault 等の安全な手段で管理してください。

参考:
- ルートの `README.md`
- `ansible_collections/yamisskey/servers/README.md`
