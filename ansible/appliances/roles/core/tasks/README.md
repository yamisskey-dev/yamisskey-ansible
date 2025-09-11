# ansible/appliances/roles/core/tasks

このディレクトリは、`core` ロールのタスク定義を格納します。

- 目的: TrueNAS アプライアンスでの基盤設定（データセット、ユーザ/グループ等）を管理します。
- 実体: `main.yml` と分割タスク

使い方:
- 変更時は関連プレイブックで確認してください。
  - 例: `make check PLAYBOOK=setup TARGET=appliances`

