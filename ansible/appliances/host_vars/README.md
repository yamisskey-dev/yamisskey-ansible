# ansible/appliances/host_vars

このディレクトリは、TrueNAS アプライアンス向けの Ansible ホスト変数 (`host_vars`) を格納します。

- 目的: ホスト（1 台ごと）に固有の設定値を定義します。
- 形式: `*.yml`（YAML）。ファイル名がホスト名になります（例: `truenas.yml`）。

使い方:
- 変数を追加・更新したら、対象プレイブックを実行します。
  - 確認実行: `make check PLAYBOOK=setup TARGET=appliances`
  - 本番実行: `make run PLAYBOOK=setup TARGET=appliances`

注意:
- 秘密情報は Ansible Vault またはパスワードストアを使用してください。

参考:
- ルートの `README.md`
- `ansible/appliances/README.md`

