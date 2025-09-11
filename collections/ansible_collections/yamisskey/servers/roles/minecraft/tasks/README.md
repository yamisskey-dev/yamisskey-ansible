# ansible/servers/roles/minecraft/tasks

`minecraft` ロールのタスク定義を格納します。`minecraft.yml` プレイブックからロールが呼び出されます。

主な内容（`tasks/main.yml`）:
- ディレクトリ作成: `{{ minecraft_dir }}` と配下 `data/`
- 秘密情報の初期化/保持: `minecraft_secrets_file` に `admin_uuid` と `rcon_password`
- テンプレート展開:
  - `.env` → `minecraft.env.j2`
  - `docker-compose.yml` → `docker-compose.yml.j2`
  - `Geyser/Floodgate` 設定 → `geyser-config.yml.j2` / `floodgate-config.yml.j2`
  - `server.properties` → `server.properties.j2`
- Docker Compose 起動 + プラグイン初期化後の強制上書き
- 任意の PlayIt.gg セットアップ補助（APT レポジトリ追加など）

実行例:
- 確認: `make check PLAYBOOK=minecraft`
- 実行: `make run PLAYBOOK=minecraft`
