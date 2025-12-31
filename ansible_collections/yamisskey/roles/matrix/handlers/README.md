# yamisskey.servers role: matrix - handlers

`matrix` ロールのハンドラを格納します。`handlers/main.yml` には以下が含まれます。

- `Restart Cloudflared`: `systemd` 経由で `cloudflared` を再起動
- `Restart Docker`: `systemd` 経由で Docker を再起動（`become: true`）
- `Restart element`: `/var/www/element` の Compose プロジェクトを再起動
