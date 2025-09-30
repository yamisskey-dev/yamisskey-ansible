# yamisskey.servers role: zitadel

Zitadel（IDaaS）の導入・設定を行うロールです。

## シークレット

`host_vars/<host>/secrets.yml`（SOPS）に `zitadel` セクションを用意してください。

```yaml
zitadel:
  masterkey: "replace-with-real-master-key"
  postgresql:
    user: zitadel
    password: "strong-db-password"
    database: zitadel
    host: db
```

ロールはこれらの値を読み込んで Docker Compose と環境変数を構成します。設定されていない場合はプレースホルダー値で警告します。

## 実行例

- 呼び出し例: `make run PLAYBOOK=zitadel`
