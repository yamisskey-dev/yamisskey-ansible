# yamisskey.servers role: misskey-proxy - vars

`misskey-proxy` ロールの変数定義を格納します。`vars/main.yml` には以下のような値が含まれます。

- パス類: `proxy_dir`, `proxy_squid_config_dir`, `squid_cache_dir`, `squid_log_dir`
- ポート/サービス: `squid_port`, `proxy_containers[].port`
- 依存サービスの IP: `misskey_server_ips`（`host_vars`/`group_vars` で上書き推奨）
- リポジトリ: `summaly_repo`, `summaly_dir`

関連プレイブック:
- `make run PLAYBOOK=misskey-proxy`
