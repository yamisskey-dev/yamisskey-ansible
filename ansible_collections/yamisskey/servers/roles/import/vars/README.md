# ansible/servers/roles/import/vars

`import` ロールの変数定義を格納します。`export` ロールと同一スキーマを使用します。

```yaml
backup_dir: /var/backups
docker_services_www: [misskey, synapse, vikunja]
docker_services_opt: [misskey-backup, minio]
docker_services_home: [ai, ctfd]
```
