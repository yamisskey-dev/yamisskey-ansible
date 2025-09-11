# yamisskey.servers role: security - vars

`security` ロールの変数定義を格納します。主要パラメータ例:

```yaml
ufw_ports: [22, 80, 443]
tailscale_ports: [41641]
cloudflared_quic_port: 7844
cloudflared_https_port: 443
warp_wireguard_ports: [2408, 500, 1701, 4500, 51820]
cloudflare_warp_ips:
  - 162.159.137.105
  - 162.159.138.105
  - 2606:4700:7::a29f:8969
  - 2606:4700:7::a29f:8a69
  - 162.159.36.1
  - 162.159.46.1
  - 2606:4700:4700::1111
  - 2606:4700:4700::1001
  - 162.159.193.0/24
  - 2606:4700:100::/48
sysctl_settings:
  - { name: 'kernel.kptr_restrict', value: '2' }
  - { name: 'net.core.bpf_jit_harden', value: '2' }
  # ...（多数の最適化・強化項目）
```

ヒント:
- IPレンジは運用環境に合わせて見直し推奨
- `sysctl` はディストリビューションやワークロードに応じて調整
