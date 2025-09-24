# yamisskey.servers role: vikunja - vars

`vikunja` ロールの変数定義を格納します。`vars/main.yml` の主な値:

- `vikunja_server_name`: 例 `task.{{ domain }}`
- `vikunja_secrets_file`: 例 `/var/www/vikunja/secrets.yml`

関連プレイブック:
- 確認: `make check PLAYBOOK=vikunja`
- 実行: `make run PLAYBOOK=vikunja`
