# yamisskey.servers role: mcaptcha

mCaptcha（プライバシー重視の CAPTCHA）の導入・設定を行うロールです。

## シークレットの定義

ホストごとの SOPS 管理シークレットに `mcaptcha` ツリーを用意してください（例: `deploy/servers/host_vars/balthasar/secrets.yml`）。

```yaml
mcaptcha:
  postgresql:
    user: mcaptcha
    password: super-secure-password
    database: mcaptcha
  cookie_secret: very-secret-cookie
  captcha_salt: ultra-secret-salt
```

ロールは `mcaptcha.<キー>` を自動で読み込み、 `.env-docker-compose` および Docker Compose に反映します。値が不足している場合は実行時に失敗します。

## 実行例

- 呼び出し例: `make run PLAYBOOK=mcaptcha`
