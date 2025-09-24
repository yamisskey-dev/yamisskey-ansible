# yamisskey.appliances role: apps - tasks

このディレクトリは、`apps` ロールのタスク定義を格納します。

- 目的: TrueNAS 上のアプリ周辺設定をタスクとして管理します。
- 実体: `main.yml` ほか分割タスク

使い方:
- プレイブックからロールが呼び出されると、ここにあるタスクが実行されます。
- 変更時は関連プレイブックで確認: `make check PLAYBOOK=migrate-minio-truenas TARGET=appliances`

