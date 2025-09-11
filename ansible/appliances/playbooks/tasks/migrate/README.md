# ansible/appliances/playbooks/tasks/migrate

このディレクトリは、MinIO 移行（TrueNAS 連携）のタスク群を格納します。

- 目的: 移行プレイブック（例: `migrate-minio-phase-a.yml` など）からインクルードされる個別タスクを分割管理します。
- 構成: `00_*.yml` 〜 `90_*.yml` の順に実行されるステップタスク

使い方:
- 個別タスクを修正したら、関連プレイブックで確認します。
  - 確認実行: `make check PLAYBOOK=migrate-minio-phase-a TARGET=appliances`
  - 本番実行: `make run PLAYBOOK=migrate-minio-phase-a TARGET=appliances`

参考:
- `ansible/appliances/playbooks/README.md`
- ルートの `README.md`

