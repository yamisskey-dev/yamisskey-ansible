# ansible/servers/roles/misskey-backup/templates

`misskey-backup` ロールの Jinja2 テンプレートを格納します。以下のテンプレートが `tasks/main.yml` から利用されます。

- `rclone.conf.j2` → `/opt/misskey-backup/config/rclone.conf`
  - 期待する値（Vault 推奨）:
    - `RCLONE_CONFIG_BACKUP_ACCESS_KEY_ID`
    - `RCLONE_CONFIG_BACKUP_SECRET_ACCESS_KEY`
    - `RCLONE_CONFIG_BACKUP_ENDPOINT`
    - `RCLONE_CONFIG_BACKUP_BUCKET_ACL`

実行例:
- 確認: `make check PLAYBOOK=misskey-backup`
- 実行: `make run PLAYBOOK=misskey-backup`
