# yamisskey.servers role: minecraft - tasks

`minecraft` ロールのタスク定義を格納します。`minecraft.yml` プレイブックからロールが呼び出されます。

主な内容（`tasks/main.yml`）:
- ディレクトリ作成: `{{ minecraft_dir }}` と配下 `data/`
- 秘密情報の読込: host_vars `<host>/secrets.yml` の `minecraft.admin_uuid` / `minecraft.rcon_password`（SOPS 管理）
- テンプレート展開:
  - `.env` → `minecraft.env.j2`
  - `docker-compose.yml` → `docker-compose.yml.j2`
  - `Geyser/Floodgate` 設定 → `geyser-config.yml.j2` / `floodgate-config.yml.j2`
  - `server.properties` → `server.properties.j2`
- Docker Compose 起動 + プラグイン初期化後の強制上書き
- 任意の PlayIt.gg セットアップ補助（APT レポジトリ追加など）

シークレット例:
```yaml
minecraft:
  admin_uuid: d02c78bf-944c-4cd0-9a0c-9363ae3dcf25
  rcon_password: ultra-secure-rcon-password
```

実行例:
- 確認: `make check PLAYBOOK=minecraft`
- 実行: `make run PLAYBOOK=minecraft`
