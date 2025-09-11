# ansible/servers/roles/import/tasks

`import` ロールのタスク定義を格納します。宛先サーバでバックアップの展開と Compose 再起動を行います。

主な処理:
- `/var/www`, `/opt`, `/home/{{ ansible_user }}` の各サービス用バックアップを展開
- 各ディレクトリで `docker-compose up -d` を実行して起動

代表変数は `export` ロールと同一（`docker_services_www` など）。

インベントリ構成:
- `destination` グループのホストで動作します。
