# ansible/appliances/group_vars

このディレクトリは、TrueNAS アプライアンス向けの Ansible グループ変数 (`group_vars`) を格納します。

- 目的: グループ単位で共有される設定値を定義します。
- 形式: `*.yml`（YAML）。ファイル名がグループ名になります（例: `all.yml`）。

使い方:
- 変数を追加・更新したら、対象プレイブックを実行します。
  - 確認実行: `make check PLAYBOOK=setup TARGET=appliances`
  - 本番実行: `make run PLAYBOOK=setup TARGET=appliances`

参考:
- ルートの `README.md` にある Makefile 統合コマンドの説明
- `ansible/appliances/README.md`（アプライアンス全体のガイド）

