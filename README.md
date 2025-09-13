# yamisskey-provision

A unified Ansible infrastructure management toolkit with an intuitive Makefile wrapper for deploying and managing servers and appliances (TrueNAS) with equal ease.

## Overview

This repository provides a comprehensive infrastructure-as-code solution with:
- **🚀 Unified Ansible Wrapper**: Simple, consistent commands for both servers and appliances
- **🎯 Dual Target Support**: Seamless switching between servers and TrueNAS appliances
- **📦 Automatic Setup**: Cross-platform Ansible management via uv
- **💾 Smart Backups**: Target-specific inventory backups with timestamps
- **🔍 Error Handling**: Clear error messages and validation
- **📋 Discovery Tools**: List available playbooks and create inventories
- **✅ Production Quality**: 100% Ansible Lint compliance with enterprise-grade reliability

## 🔐 Security & Vault Configuration

### Ansible Vault Setup

This project uses Ansible Vault for secure secret management. Before running playbooks, set up your vault:

```bash
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
ansible-vault create deploy/servers/group_vars/vault.yml --vault-password-file .vault_pass
```

### Required Vault Variables

Add these encrypted variables to your vault files:

```yaml
vault_balthasar_sudo_password: "secure_password_here"
vault_caspar_sudo_password: "secure_password_here"
vault_joseph_sudo_password: "secure_password_here"
vault_raspberrypi_sudo_password: "secure_password_here"
vault_linode_prox_sudo_password: "secure_password_here"
minio_root_user: "admin"
minio_root_password: "secure_minio_password"
minio_kms_master_key: "minio-master-key:base64-encoded-key"
truenas_api_token: "api-token-here"
truenas_minio_root_user: "admin"
truenas_minio_root_password: "secure_password"
truenas_minio_kms_key: "kms-encryption-key"
cloudflare_tunnel_id: "tunnel-uuid-here"
cloudflare_tunnel_token: "tunnel-token-here"
cloudflare_tunnel_credentials: "credentials-json-here"
```

### Vault Usage Examples

```bash
ansible-vault edit deploy/servers/group_vars/vault.yml --vault-password-file .vault_pass
make run PLAYBOOK=common --extra-vars "@deploy/servers/group_vars/vault.yml" --vault-password-file .vault_pass
ansible-vault encrypt deploy/servers/host_vars/production_secrets.yml
```

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

Install Ansible and Collections:
```bash
make install
ansible-galaxy collection install -r requirements.yml
```

Create inventory (choose your target):
```bash
make inventory
make inventory TARGET=appliances
```

### 2.1 Collections Installation

The project uses modern Ansible Collections. Install them automatically:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list | grep yamisskey
ansible-galaxy collection list | grep -E "(community|ansible)"
```

### 3. Basic Usage

Get help:
```bash
make help
```

Run a playbook on servers (default):
```bash
make run PLAYBOOK=common
```

Run a playbook on appliances:
```bash
make run PLAYBOOK=setup TARGET=appliances
```

Check what would be changed (dry-run):
```bash
make check PLAYBOOK=security
make check PLAYBOOK=migrate-minio-phase-a TARGET=appliances
```

## 🎯 Unified Command System

All commands work consistently across both targets using the `TARGET` parameter:

### Core Commands

| Command | Description | Server Example | Appliance Example |
|---------|-------------|----------------|-------------------|
| `run` | Execute playbook | `make run PLAYBOOK=common` | `make run PLAYBOOK=setup TARGET=appliances` |
| `check` | Dry-run with diff | `make check PLAYBOOK=security` | `make check PLAYBOOK=migrate-minio-phase-a TARGET=appliances` |
| `deploy` | Run multiple playbooks | `make deploy PLAYBOOKS='common security'` | `make deploy PLAYBOOKS='setup migrate-minio-phase-a' TARGET=appliances` |
| `list` | Show available playbooks | `make list` | `make list TARGET=appliances` |

### Management Commands

| Command | Description | Server Example | Appliance Example |
|---------|-------------|----------------|-------------------|
| `inventory` | Create inventory | `make inventory` | `make inventory TARGET=appliances` |
| `backup` | Backup inventory | `make backup` | `make backup TARGET=appliances` |
| `logs` | View recent logs | `make logs` | `make logs` |

### Advanced Parameters

Add these parameters to any `run`, `check`, or `deploy` command:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `LIMIT=<hosts>` | Target specific hosts | `make run PLAYBOOK=common LIMIT=local` |
| `TAGS=<tags>` | Run only specific tags | `make run PLAYBOOK=security TAGS=firewall,ssh` |

## 📋 Complete Provisioning Workflows

### New Server Setup

1. **Initial Setup**
   ```bash
   make install
   make inventory
   make backup
   ```

2. **Base System Configuration**
   ```bash
   make run PLAYBOOK=common
   make run PLAYBOOK=security
   ```

3. **Service Installation**
   ```bash
   make run PLAYBOOK=monitoring
   make run PLAYBOOK=minio
   make run PLAYBOOK=misskey
   ```

### Misskey Instance Deployment

Complete Misskey setup workflow:

```bash
make deploy PLAYBOOKS='common security modsecurity-nginx monitoring minio misskey'
make check PLAYBOOK=common
make run PLAYBOOK=common
make check PLAYBOOK=misskey
make run PLAYBOOK=misskey
```

### TrueNAS Appliance Setup

Complete TrueNAS appliance management:

```bash
make inventory TARGET=appliances
make backup TARGET=appliances
make deploy PLAYBOOKS='setup migrate-minio-phase-a' TARGET=appliances
make check PLAYBOOK=setup TARGET=appliances
make run PLAYBOOK=setup TARGET=appliances
make run PLAYBOOK=migrate-minio-truenas TARGET=appliances
```

### Mixed Environment Management

Managing both servers and appliances:

```bash
make list TARGET=servers
make run PLAYBOOK=common TARGET=servers
make list TARGET=appliances
make run PLAYBOOK=setup TARGET=appliances
make backup TARGET=servers
make backup TARGET=appliances
```

## 🚀 Advanced Usage

### Combining Parameters
```bash
make run PLAYBOOK=security LIMIT=local TAGS=firewall,ssh
make check PLAYBOOK=migrate-minio-phase-a TARGET=appliances LIMIT=truenas.local
make deploy PLAYBOOKS='common security' TAGS=install,config
```

### Quick Reference
```bash
make help
make install
make inventory
make inventory TARGET=appliances
make list
make list TARGET=appliances
make run PLAYBOOK=common
make run PLAYBOOK=setup TARGET=appliances
make backup
make backup TARGET=appliances
```

This unified system provides consistent, predictable commands that work the same way whether you're managing traditional servers or TrueNAS appliances.
