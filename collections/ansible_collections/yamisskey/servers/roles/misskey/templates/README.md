# ansible/servers/roles/misskey/templates

`misskey` ロールの Jinja2 テンプレートを格納します。`tasks/main.yml` から以下のテンプレートが展開されます。

- `misskey_docker-compose.yml.j2` → `{{ misskey_dir }}/docker-compose.yml`
- `docker_example.yml.j2` → `{{ misskey_dir }}/.config/default.yml`
- `docker_example.env.j2` → `{{ misskey_dir }}/.config/docker.env`
- `misskey_postgresql.conf.j2` → `{{ misskey_dir }}/.config/postgresql.conf`

実行例:
- 確認: `make check PLAYBOOK=misskey`
- 実行: `make run PLAYBOOK=misskey`
