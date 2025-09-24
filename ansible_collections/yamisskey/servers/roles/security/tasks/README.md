# yamisskey.servers role: security - tasks

`security` ロールのタスク定義を格納します。ログ整備、UFW、Fail2ban、Cloudflare/WARP対応、sysctl強化などのハードニングを行います。

主な処理:
- 依存パッケージ導入: `rsyslog`, `logrotate`, `ufw`, `tailscale`, `fail2ban`, `lynis`
- `rsyslog.conf` のテンプレート適用、`logrotate` 設定の配備
- UFW 既定ポリシー設定 + 指定ポート許可（`ufw_ports`, `tailscale_ports`）
- Cloudflare Tunnel/HTTPS/WARP 用のポートと IP 範囲の許可
- `warp-cli` を用いた WARP 登録/ライセンス適用/接続/除外ホスト設定
- `sysctl` による OS 強化（BPF/ネットワーク/カーネル/メモリ等）

代表変数（`vars/main.yml` より抜粋）:
```yaml
ufw_ports: [22, 80, 443]
tailscale_ports: [41641]
cloudflared_quic_port: 7844
cloudflared_https_port: 443
warp_wireguard_ports: [2408, 500, 1701, 4500, 51820]
cloudflare_region1_ips_v4: ["162.159.192.0/24", "162.159.193.0/24", ...]
cloudflare_region1_ips_v6: ["2606:4700:.../48", ...]
# 省略: 他にも region2、WARP 関連 IP、sysctl_settings など
```

実行例:
- 確認: `make check PLAYBOOK=security`
- 実行: `make run PLAYBOOK=security`
