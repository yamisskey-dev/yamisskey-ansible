# yamisskey.servers role: monitoring - vars

`monitoring` ロールの変数定義を格納します。

代表変数（例）:
```yaml
grafana_server_name: grafana.{{ domain }}

# 監視するローカルポートの例（prometheus.yml.j2 側で参照）
# host_services.
```

環境ごとに `host_vars` や `group_vars` で `host_services.*` を定義し、エンドポイントのポートを調整してください。
