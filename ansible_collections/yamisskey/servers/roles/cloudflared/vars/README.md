# yamisskey.servers role: cloudflared - vars

`cloudflared` ロールの変数定義を格納します。最低限必要な値の例:

```yaml
cloudflared_config_dir: /etc/cloudflared
cloudflared_system_config_dir: /etc/cloudflared
cloudflared_user: root
cloudflared_group: root
cloudflared_skip_install: false

# トンネル/ドメイン
cloudflared_tunnel_name: raspberrypi-yaminio
cloudflared_hostname: drive.{{ domain }}
# cloudflared_tunnel_uuid: <既存トンネルのUUID>

# Cloudflare API（自動化する場合に必要）
# cloudflare_api_token: "..."          # VAULT 推奨
# cloudflare_zone_id: "..."            # VAULT 推奨
# cloudflare_account_id: "..."         # VAULT 推奨
```

機微情報は必ず SOPS (group_vars/all/secrets.yml など) で管理してください。
