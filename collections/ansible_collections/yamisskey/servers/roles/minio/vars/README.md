# ansible/servers/roles/minio/vars

`minio` ロールの変数定義を格納します。`vars/main.yml` の主な値:

```yaml
minio_alias: yaminio
minio_api_server_name: "drive.{{ domain }}"
minio_web_server_name: "minio.{{ domain }}"
minio_bucket_name_for_misskey: "files"
minio_bucket_name_for_outline: "assets"
minio_secrets_file: '/opt/minio/secrets.yml'
```

上書き例（`group_vars/all.yml` など）:
```yaml
minio_alias: default
minio_secrets_file: '/srv/minio/secrets.yml'
```

機微情報は Ansible Vault で管理してください。
