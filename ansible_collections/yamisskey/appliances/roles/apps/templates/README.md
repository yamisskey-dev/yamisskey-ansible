# ansible/appliances/roles/apps/templates

このディレクトリは、`apps` ロールで使用する Jinja2 テンプレートを格納します。

- 目的: アプリ関連の設定ファイルを変数から生成します。
- 拡張子: `*.j2`

使い方:
- テンプレート修正後は対象プレイブックで確認してください。
  - 例: `make check PLAYBOOK=migrate-minio-truenas TARGET=appliances`

