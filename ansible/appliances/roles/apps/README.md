# ansible/appliances/roles/apps

このディレクトリは、TrueNAS アプライアンス上で稼働させるアプリ周りのロールを集約します。

- 目的: MinIO 等のアプリケーションに関するテンプレート・タスクをまとめて提供します。
- 下層: `tasks/`, `templates/` など標準的な Ansible ロール構成

使い方:
- 対応するアプライアンス向けプレイブックから呼び出されます。
  - 例: `make run PLAYBOOK=migrate-minio-truenas TARGET=appliances`

参考:
- `ansible/appliances/roles/README.md`
- ルートの `README.md`

