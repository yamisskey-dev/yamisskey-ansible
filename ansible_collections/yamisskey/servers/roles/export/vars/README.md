# yamisskey.servers role: export - vars

`export` ロールの変数定義を格納します。

```yaml
backup_dir: /var/backups
docker_services_www:
  - misskey
  - synapse
  - vikunja
docker_services_opt:
  - misskey-backup
  - minio
docker_services_home:
  - ai
  - ctfd
```

インベントリ例（抜粋）:
```ini
[source]
source-host ansible_host=...

[destination]
destination-host ansible_host=...
```
