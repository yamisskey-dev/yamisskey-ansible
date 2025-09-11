# ansible/appliances/playbooks/templates

このディレクトリは、アプライアンス（TrueNAS）向けプレイブックで使用する Jinja2 テンプレートを格納します。

- 目的: 設定ファイルや構成スニペットを変数から生成します。
- 拡張子: `*.j2`

使い方:
- テンプレートを追加・変更したら、関連するプレイブックで動作確認します。
  - 確認実行: `make check PLAYBOOK=setup TARGET=appliances`
  - 本番実行: `make run PLAYBOOK=setup TARGET=appliances`

参考:
- `ansible/appliances/playbooks/README.md`
- ルートの `README.md`（Make ターゲットの一覧）

