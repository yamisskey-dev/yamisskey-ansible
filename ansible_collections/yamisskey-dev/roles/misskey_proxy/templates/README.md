# yamisskey.servers role: misskey-proxy - templates

`misskey-proxy` ロールの Jinja2 テンプレートを格納します。

- `squid.conf.j2` → `{{ proxy_squid_config_dir }}/squid.conf`

注意:
- `squid_port` は `host_services.linode_prox.squid` に依存します。`host_vars` で設定してください。
