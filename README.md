# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management.

## System Requirements

- Linux distribution providing a writable `systemd`
- Python 3 available to install `ansible` via `uv`
- Go available to install `sops` and `age`

## Prerequisites

Install minimum required packages
- [task](https://taskfile.dev/)
- [tailscale](https://tailscale.com/download/linux)

Ensure servers can be reached in Tailscale
```bash
tailscale login
sudo tailscale up --advertise-tags=tag:ssh-access --ssh --accept-dns=false --reset --accept-risk=lose-ssh
```

Ensure you have access via Tailscale SSH
```bash
tailscale ssh <hostname>
```

## Install

```bash
git clone https://github.com/yamisskey-dev/yamisskey-provision.git
cd yamisskey-provision
task install
task inventory
```

`ansible` and `sops` will be installed.

## Help

```bash
task help
```
