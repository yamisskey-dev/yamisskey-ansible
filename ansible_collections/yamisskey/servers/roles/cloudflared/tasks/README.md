# yamisskey.servers role: cloudflared - tasks

`cloudflared` ロールのタスク定義を格納します。インストール、トンネル作成、DNS更新、設定配備、systemd サービス設定、検証まで自動化（API 資格情報がある場合）。

代表フロー:
- 必要ならインストール（`cloudflared_skip_install: false` の場合）
- トンネル作成（`cloudflare_api_token`, `cloudflare_zone_id`, `cloudflare_account_id` 提供時）
- DNS レコード更新（作成済みトンネル UUID がある場合）
- `config.yml.j2` の配備と systemd サービス設定
- 接続検証（トンネル UUID がある場合）

実行例:
- 確認: `make check PLAYBOOK=cloudflared`
- 実行: `make run PLAYBOOK=cloudflared`
