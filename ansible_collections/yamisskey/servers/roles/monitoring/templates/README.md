# yamisskey.servers role: monitoring - templates

`monitoring` ロールの Jinja2 テンプレートを格納します。

- `blackbox.yml.j2` → `/etc/blackbox_exporter/blackbox.yml`
- `prometheus.yml.j2` → `/etc/prometheus/prometheus.yml`

テンプレート修正後は `promtool check config /etc/prometheus/prometheus.yml` による検証が行われます。
