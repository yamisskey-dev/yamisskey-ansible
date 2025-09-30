# yamisskey.servers role: vikunja

Vikunja（タスク管理）の導入・設定を行うロールです。

## シークレット

`host_vars/<host>/secrets.yml`（SOPS）に `vikunja` セクションを用意してください。

```yaml
vikunja:
  jwt_secret: "replace-with-real-secret"
  db_root_password: "super-secure-root"
  db_user: "vikunja"
  db_password: "super-secure-db-password"
  mailer_password: "smtp-password"
```

ロールはこれらの値を参照して Docker Compose と環境変数を構成します。未設定の場合はプレースホルダー値で警告します。

## 実行例

- 呼び出し例: `make run PLAYBOOK=vikunja`
