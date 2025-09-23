# yamisskey.servers role: cloudflare-warp - tasks

`cloudflare-warp` ロールのタスク定義を格納します。`warp-cli` を利用し、WARP の登録/ライセンス適用/接続/モード設定/除外ホスト設定までを自動化します。

必要条件:
- 対象に WARP クライアント（`warp-cli`）がインストール済みであること（未導入ならこのロールは失敗します）。

代表変数（`group_vars`/`host_vars` に設定）:
```yaml
warp_service_name: cloudflare-warp
warp_license_key: ""           # ある場合のみ適用（Vault推奨）
warp_mode: warp                 # 例: warp / doh / proxy (環境に応じて)
warp_verify_timeout: 15
warp_excluded_hosts:
  - 10.0.0.0/8
  - 192.168.0.0/16
```

実行例:
- 確認: `yamisskey-provision check cloudflare-warp`
- 実行: `yamisskey-provision run cloudflare-warp`
