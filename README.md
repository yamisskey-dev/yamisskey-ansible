# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management.

## 🚀 Quick Start

### Prerequisites

- make
- sops
- age

### System Requirements

- Linux distribution providing a writable `systemd` (e.g. Ubuntu 22.04 LTS)
- Python 3 available as `/usr/bin/python3`, `ansible` will be installed via `uv`.

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
make help
```
