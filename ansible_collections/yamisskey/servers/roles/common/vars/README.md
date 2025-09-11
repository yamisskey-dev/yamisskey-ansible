# yamisskey.servers role: common - vars

`common` ロールの変数定義を格納します。代表値:

```yaml
packages:
  - btop
  - net-tools
  - nmap
  - inetutils-traceroute
  - rsync
  - zip
  - tor
  - mecab
  - libmecab-dev
  - mecab-ipadic-utf8
  - prometheus
  - rclone
  - fail2ban
  - unattended-upgrades
  - debsums
  - apt-show-versions
  - clamav
  - clamav-daemon
  - lynis
  - apparmor
  - auditd
  - sysstat
  - python3-passlib
```

上書き例:
```yaml
packages: [git, curl, htop]
```
