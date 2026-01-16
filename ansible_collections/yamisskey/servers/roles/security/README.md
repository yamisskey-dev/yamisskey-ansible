# yamisskey.servers role: security

セキュリティ強化（Firewall、カーネルハードニング等）を行うロールです。

- 呼び出し例: `make run PLAYBOOK=security`

## 機能

### 1. ファイアウォール (UFW)
- デフォルト拒否ポリシー
- Cloudflare Tunnel/WARP対応
- Docker監視ポートのホワイトリスト

### 2. SSH強化
- デュアルポート (22, 2222)
- 公開鍵認証

### 3. DNS暗号化
- dnscrypt-proxy (DNSSEC強制)
- systemd-resolved連携

### 4. マルウェアスキャン
- ClamAV定期スキャン

### 5. カーネルハードニング (eBPF/grsecurity/PaX相当)

Ubuntu標準カーネルで実現可能な最大限のハードニングを提供します。

#### sysctl設定
| 設定 | 値 | 効果 |
|------|-----|------|
| `kernel.unprivileged_bpf_disabled` | 1 | 非特権ユーザーのeBPF禁止 |
| `net.core.bpf_jit_harden` | 2 | BPF JIT厳格ハードニング |
| `kernel.kptr_restrict` | 2 | カーネルポインタ完全隠蔽 |
| `kernel.perf_event_paranoid` | 3 | パフォーマンスイベント制限 |
| `kernel.yama.ptrace_scope` | 1 | ptrace制限 |
| `kernel.io_uring_disabled` | 2 | io_uring完全無効 |
| `kernel.kexec_load_disabled` | 1 | ランタイムカーネル置換禁止 |
| `user.max_user_namespaces` | (無効) | Docker互換性のため無効化 |

#### GRUBカーネルパラメータ
```
# Spectre/Meltdown緩和
spectre_v2=on spec_store_bypass_disable=on l1tf=full,force mds=full,nosmt

# IOMMU保護
iommu=force intel_iommu=on amd_iommu=on

# メモリ保護 (PaX MEMORY_SANITIZE相当)
init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 slab_nomerge pti=on

# セキュリティ強化
debugfs=off lockdown=confidentiality vsyscall=none randomize_kstack_offset=on
```

#### カーネルモジュールブラックリスト
以下のモジュールはロードをブロック:
- 不要なファイルシステム: cramfs, freevxfs, hfs, hfsplus, jffs2, squashfs, udf
- 危険なネットワークプロトコル: dccp, sctp, rds, tipc
- DMA攻撃ベクトル: firewire-*, thunderbolt
- 攻撃面削減: bluetooth, btusb, vivid

## 変数

### カーネルハードニング
```yaml
# 有効化/無効化
security_kernel_hardening_enabled: true

# GRUBパラメータ (カスタマイズ可能)
security_grub_cmdline_extra:
  - "spectre_v2=on"
  # ... 詳細はdefaults/main.yml参照

# モジュールブラックリスト (カスタマイズ可能)
security_kernel_module_blacklist:
  - dccp
  - sctp
  # ... 詳細はdefaults/main.yml参照

# lockdownモード: integrity または confidentiality
security_lockdown_mode: "confidentiality"

# io_uring制限 (0=許可, 1=CAP_SYS_ADMIN必要, 2=完全無効)
security_io_uring_disabled: 2
```

## 注意事項

### Dockerとの互換性
本ロールはDocker環境との互換性を考慮しています:
- `net.ipv4.conf.all.forwarding=1` (コンテナ間通信に必要)
- `user.max_user_namespaces` は無効化 (Docker rootless対応)
- `squashfs` モジュールはSnapパッケージ用に除外

### 再起動が必要
GRUBパラメータの変更は再起動後に有効になります。

### Hardened Gentoo/grsecurityとの比較
| 機能 | grsecurity | このロール |
|------|-----------|-----------|
| RBAC | ○ | × (AppArmorで代替) |
| PaX MPROTECT | ○ | △ (pti=on) |
| MEMORY_SANITIZE | ○ | ○ (init_on_alloc/free) |
| eBPF制限 | ○ | ○ |
| カーネルポインタ隠蔽 | ○ | ○ |
| モジュール制限 | ○ | ○ |
| Lockdown | × | ○ (Ubuntu 5.4+) |
