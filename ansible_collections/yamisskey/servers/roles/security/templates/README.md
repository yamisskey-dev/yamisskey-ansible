# yamisskey.servers role: security - templates

`security` ロールの Jinja2 テンプレートを格納します。主なテンプレートと配置先:

- `rsyslog.conf.j2` → `/etc/rsyslog.conf`
- `logrotate_rsyslog.j2` → `/etc/logrotate.d/rsyslog`
- `resolved.conf.j2` → `/etc/systemd/resolved.conf`
- `clamd.conf.j2` → `/etc/clamav/clamd.conf`

テンプレート変更後は `make check PLAYBOOK=security` で差分と適用影響を確認してください。
