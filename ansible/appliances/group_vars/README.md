# ansible/appliances/group_vars

このディレクトリは、TrueNAS アプライアンス向けの Ansible グループ変数 (`group_vars`) を格納します。`all.yml` に共通設定が定義されています。

主な変数例（`all.yml` より抜粋）:
- TrueNAS/MinIO: `truenas_scale_version`, `truenas_minio_region`, `truenas_minio_api_port`, `truenas_minio_console_port`
- ZFS/スナップショット: `truenas_zfs_recordsize_minio`, `truenas_snapshot_retention_days`
- Cloudflared: `truenas_cloudflared_protocol`, `truenas_cloudflared_keep_alive_timeout`
- アプリ管理: `truenas_manage_custom_compose`（Custom AppのcomposeをAnsibleで管理するか）

使い方:
- 変数を更新後、関連プレイブックを実行します。
  - 確認: `make check PLAYBOOK=setup TARGET=appliances`
  - 実行: `make run PLAYBOOK=setup TARGET=appliances`
- 個別ホストで上書きが必要な値は `host_vars/<host>.yml` で定義します。

参考: ルートの `README.md`（Make コマンド集）
