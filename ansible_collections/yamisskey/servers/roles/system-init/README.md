# System Init ロール

システム初期化と必要な依存関係をインストールするAnsibleロール

## 概要

このロールは、新しいサーバーのシステム初期化を行い、以下のツールとサービスをインストールします：

- Docker Engine および Docker Compose
- Tailscale VPN
- Cloudflare WARP
- Cloudflared tunnel
- Playit トンネル

## 必要条件

- Ubuntu/Debian系Linux
- sudo権限を持つユーザー
- インターネット接続

## ロール変数

### デフォルト変数 (defaults/main.yml)

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `install_docker` | `true` | Dockerをインストールするかどうか |
| `install_tailscale` | `true` | Tailscaleをインストールするかどうか |
| `install_cloudflare` | `true` | Cloudflare製品をインストールするかどうか |
| `install_warp` | `true` | Cloudflare WARPをインストールするかどうか |
| `install_cloudflared` | `true` | Cloudflaredをインストールするかどうか |
| `install_playit` | `true` | Playitをインストールするかどうか |
| `verify_installations` | `true` | インストール後の検証を行うかどうか |

## 依存関係

- `yamisskey.servers.common` (利用可能な場合)

## 使用例

### 基本的な使用方法

```yaml
- hosts: all
  become: true
  roles:
    - yamisskey.servers.system-init
```

### 選択的インストール

```yaml
- hosts: all
  become: true
  roles:
    - role: yamisskey.servers.system-init
      vars:
        install_playit: false
        install_warp: false
```

### タグを使用した部分実行

```bash
# Dockerのみインストール
ansible-playbook -i inventory playbook.yml --tags docker

# 検証のみ実行
ansible-playbook -i inventory playbook.yml --tags verify
```

## 利用可能なタグ

- `packages`: パッケージ関連タスク
- `docker`: Docker インストール
- `tailscale`: Tailscale インストール
- `cloudflare`: Cloudflare製品インストール
- `playit`: Playit インストール
- `verify`: インストール検証
- `always`: 常に実行されるタスク

## インストール後の設定

ロール実行後、以下の設定が必要です：

1. **Tailscale設定**: `sudo tailscale up`
2. **Cloudflare WARP設定** (オプション): `warp-cli register`
3. **Dockerグループ反映**: ログアウト/ログインまたは `newgrp docker`

## ライセンス

MIT

## 作者情報

yamisskey Development Team