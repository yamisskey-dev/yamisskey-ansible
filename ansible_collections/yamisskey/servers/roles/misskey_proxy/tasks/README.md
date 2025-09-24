# yamisskey.servers role: misskey-proxy - tasks

`misskey-proxy` ロールのタスク定義を格納します。Squid・media-proxy-rs・nginx・summaly のデプロイを行います。

主な処理:
- 依存パッケージ導入（Docker, docker-compose, squid, git）と Docker 常駐化
- プロキシ関連ディレクトリの作成（`proxy_dir`, `squid_cache_dir`, `squid_log_dir`）
- `squid.conf.j2` 配備、Squid 起動
- `summaly_repo` をクローンして `example` を `docker compose up -d`
- media-proxy-rs と nginx を `docker_container` で起動
- `docker ps` の結果を表示

関連変数（`vars/main.yml` 参照、必要に応じ `host_vars` で上書き）:
```yaml
proxy_dir: /opt
proxy_squid_config_dir: /etc/squid
squid_cache_dir: /var/spool/squid
squid_log_dir: /var/log/squid
squid_port: "{{ host_services.linode_prox.squid }}"
summaly_repo: https://github.com/{{ github_org }}/summaly-docker.git
summaly_dir: "{{ proxy_dir }}/summaly-docker"
```

実行例:
- 確認: `make check PLAYBOOK=misskey-proxy`
- 実行: `make run PLAYBOOK=misskey-proxy`
