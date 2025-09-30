# yamisskey.servers role: stalwart - templates

`stalwart` ロールで使用する Jinja2 テンプレートを格納します。`stalwart.yml` プレイブックからロールが呼び出され、以下のテンプレートが展開されます。

- `stalwart_docker-compose.yml.j2` → `{{ stalwart_dir }}/docker-compose.yml`
- `stalwart_config.toml.j2` → `{{ stalwart_dir }}/etc/config.toml`

関連変数（抜粋）:
- `stalwart_dir`: 展開先のベースディレクトリ
- `stalwart_server_name`: Web UI 接続先ホスト名の表示に利用
- `stalwart.*`: host_vars `<host>/secrets.yml` で定義する管理者認証情報（SOPS 管理）

実行例:
- 確認: `make check PLAYBOOK=stalwart`
- 実行: `make run PLAYBOOK=stalwart`
