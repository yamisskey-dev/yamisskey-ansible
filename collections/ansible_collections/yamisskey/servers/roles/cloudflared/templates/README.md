# ansible/servers/roles/cloudflared/templates

`cloudflared` ロールのテンプレート（Jinja2）を格納します。

- `config.yml.j2` → `{{ cloudflared_config_dir }}/config.yml` と `{{ cloudflared_system_config_dir }}/config.yml`（サービス連携用）

代表変数（vars/host_vars で定義）:
```yaml
cloudflared_tunnel_name: raspberrypi-yaminio
cloudflared_hostname: drive.{{ domain }}
# cloudflared_tunnel_uuid: <作成済みのUUIDを設定するかAPIで生成>
```
