# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management.

## 🚀 Quick Start

### Prerequisites

- Make

### System Requirements

- Linux distribution providing a writable `systemd` (e.g. Ubuntu 22.04 LTS)
- Python 3 available as `/usr/bin/python3`, `ansible` will be installed via `uv`.

## 📦 What's Included

- **Ansible 2.17+** with complete ecosystem
- **SOPS + Age** for modern secrets management
- **Testing tools** (molecule, ansible-lint)
- **Complete Python environment** for development
- **Automatic environment loading** via direnv

## Quick Start

### 1. Prerequisites

Ensure you have access via Tailscale SSH:

```bash
tailscale login
sudo tailscale up --advertise-tags=tag:ssh-access --ssh --accept-dns=false --reset --accept-risk=lose-ssh
```

Access the server:
```bash
tailscale ssh <hostname>
```

### 2. Setup

Clone the repository:
```bash
git clone https://github.com/yamisskey-dev/yamisskey-provision.git
cd yamisskey-provision
```