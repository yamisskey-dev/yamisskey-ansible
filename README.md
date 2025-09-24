# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management.

## System Requirements

- Linux distribution providing a writable `systemd`
- Python 3 available as `/usr/bin/python3`

## Prerequisites

Install minimum required packages
- [make](https://www.gnu.org/software/make/)
- [age](https://github.com/FiloSottile/age)
- [tailscale](https://tailscale.com/download/linux)

Ensure servers can be reachedvia Tailscale SSH
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
make install
make inventory
```

`ansible` and `sops` will be installed.

## Help

```bash
make help
```