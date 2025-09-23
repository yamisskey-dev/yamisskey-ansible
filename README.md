# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management and Nix-based development environment.

## 🚀 Quick Start

### Prerequisites
- [Nix](https://nixos.org/download.html) with flakes enabled
- [direnv](https://direnv.net/) (optional but recommended)

### System Requirements
- Linux distribution providing a writable `systemd` (e.g. Ubuntu 22.04 LTS)
- Python 3 available as `/usr/bin/python3`
- [Nix](https://nixos.org/) (installed manually on hosts; Molecule prepares it automatically inside test containers)

### Automatic Environment Setup (Recommended)

If you have direnv installed:
```bash
cd yamisskey-provision
direnv allow  # Automatically loads Nix environment
```

### Manual Environment Setup

```bash
cd yamisskey-provision
nix develop  # Enter development environment manually
```

## 🔐 SOPS Secrets (Default)

This project manages all secrets with SOPS (Age recipients) and the unified `yamisskey-provision` command:

```bash
# Check SOPS status
yamisskey-provision sops status servers

# Edit secrets with SOPS
yamisskey-provision sops edit servers

# View secrets (read-only)
yamisskey-provision sops view servers
```

## 🚀 Unified Command Interface

All operations use the single `yamisskey-provision` command with intuitive subcommands:

### SOPS Operations
```bash
yamisskey-provision sops install                    # Install SOPS and Age
yamisskey-provision sops edit [target]              # Edit encrypted secrets
yamisskey-provision sops view [target]              # View decrypted secrets
yamisskey-provision sops status [target]            # Check SOPS status
```

### Ansible Operations
```bash
yamisskey-provision run <playbook> [target] [limit] # Run playbook
yamisskey-provision check <playbook> [target]       # Dry-run with diff
```

### Infrastructure Management
```bash
yamisskey-provision inventory [target] [type]       # Create inventory
yamisskey-provision status                          # Health check
yamisskey-provision list [target]                   # List playbooks
```

### Testing & Maintenance
```bash
yamisskey-provision test <role> [mode] [target]     # Test role with molecule
yamisskey-provision backup [target]                 # Backup inventory
yamisskey-provision logs                            # View recent logs
```

For detailed migration instructions, see [docs/SOPS_MIGRATION.md](docs/SOPS_MIGRATION.md).

## 📦 What's Included

- **Ansible 2.17+** with complete ecosystem
- **SOPS + Age** for modern secrets management
- **Testing tools** (molecule, ansible-lint)
- **Complete Python environment** for development
- **Automatic environment loading** via direnv


A unified Ansible infrastructure management toolkit providing enterprise-grade infrastructure automation with modern secrets management.

## Overview

This repository provides a comprehensive infrastructure-as-code solution with:
- **🚀 Unified Command Interface**: Single `yamisskey-provision` command for all operations
- **🎯 Dual Target Support**: Seamless switching between servers and TrueNAS appliances
- **🔐 Modern Secrets Management**: SOPS with Age encryption replacing Ansible Vault
- **💾 Smart Backups**: Target-specific inventory backups with timestamps
- **🔍 Error Handling**: Clear error messages and validation
- **📋 Discovery Tools**: List available playbooks and create inventories
- **✅ Production Quality**: 100% Ansible Lint compliance with enterprise-grade reliability

## 🔐 Modern SOPS Security Configuration

### SOPS Setup

This project uses SOPS (Secrets OPerationS) with Age encryption for secure secret management:

```bash
# Install SOPS and Age (automatic via Nix)
yamisskey-provision sops install

# Check status
yamisskey-provision sops status servers

# Edit secrets
yamisskey-provision sops edit servers
```

### Required Secret Variables

Add these encrypted variables to your SOPS files:

```yaml
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

### SOPS Usage Examples

```bash
# Edit secrets with SOPS
yamisskey-provision sops edit servers
# View decrypted secrets (read-only)
yamisskey-provision sops view servers
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

The Nix environment will automatically provide all dependencies:
```bash
# With direnv (automatic)
direnv allow

# Or manual
nix develop
```

Create inventory (choose your target):
```bash
yamisskey-provision inventory servers
yamisskey-provision inventory appliances
```

### 2.1 Collections Installation

The project uses modern Ansible Collections. They are automatically available in the Nix environment:

```bash
ansible-galaxy collection list | grep yamisskey
ansible-galaxy collection list | grep -E "(community|ansible)"
```

### 3. Basic Usage

Get help:
```bash
yamisskey-provision --help
```

Run a playbook on servers (default):
```bash
yamisskey-provision run common
```

Run a playbook on appliances:
```bash
yamisskey-provision run setup appliances
```

Check what would be changed (dry-run):
```bash
yamisskey-provision check security
yamisskey-provision check migrate-minio-phase-a appliances
```

## 🎯 Unified Command System

All commands work consistently across both targets using the target parameter:

### Core Commands

| Command | Description | Server Example | Appliance Example |
|---------|-------------|----------------|-------------------|
| `run` | Execute playbook | `yamisskey-provision run common` | `yamisskey-provision run setup appliances` |
| `check` | Dry-run with diff | `yamisskey-provision check security` | `yamisskey-provision check migrate-minio-phase-a appliances` |
| `list` | Show available playbooks | `yamisskey-provision list` | `yamisskey-provision list appliances` |

### Management Commands

| Command | Description | Server Example | Appliance Example |
|---------|-------------|----------------|-------------------|
| `inventory` | Create inventory | `yamisskey-provision inventory servers` | `yamisskey-provision inventory appliances` |
| `backup` | Backup inventory | `yamisskey-provision backup servers` | `yamisskey-provision backup appliances` |
| `logs` | View recent logs | `yamisskey-provision logs` | `yamisskey-provision logs` |

### Advanced Parameters

Add limit and tags to any `run` or `check` command:

| Example | Description |
|---------|-------------|
| `yamisskey-provision run common servers local` | Target specific hosts |
| `yamisskey-provision run security servers "" firewall,ssh` | Run only specific tags |

## 📋 Complete Provisioning Workflows

### New Server Setup

1. **Initial Setup**
   ```bash
   yamisskey-provision inventory servers
   yamisskey-provision backup servers
   ```

2. **Base System Configuration**
   ```bash
   yamisskey-provision run common
   yamisskey-provision run security
   ```

3. **Service Installation**
   ```bash
   yamisskey-provision run monitor
   yamisskey-provision run minio
   yamisskey-provision run misskey
   ```

### Misskey Instance Deployment

Complete Misskey setup workflow:

```bash
yamisskey-provision check common
yamisskey-provision run common
yamisskey-provision check misskey
yamisskey-provision run misskey
```

### TrueNAS Appliance Setup

Complete TrueNAS appliance management:

```bash
yamisskey-provision inventory appliances
yamisskey-provision backup appliances
yamisskey-provision check setup appliances
yamisskey-provision run setup appliances
yamisskey-provision run migrate-minio-truenas appliances
```

### Mixed Environment Management

Managing both servers and appliances:

```bash
yamisskey-provision list servers
yamisskey-provision run common servers
yamisskey-provision list appliances
yamisskey-provision run setup appliances
yamisskey-provision backup servers
yamisskey-provision backup appliances
```

## 🚀 Advanced Usage

### Combining Parameters
```bash
yamisskey-provision run security servers local firewall,ssh
yamisskey-provision check migrate-minio-phase-a appliances truenas.local
```

### Quick Reference
```bash
yamisskey-provision --help
yamisskey-provision inventory servers
yamisskey-provision inventory appliances
yamisskey-provision list
yamisskey-provision list appliances
yamisskey-provision run common
yamisskey-provision run setup appliances
yamisskey-provision backup servers
yamisskey-provision backup appliances
```

This unified system provides consistent, predictable commands that work the same way whether you're managing traditional servers or TrueNAS appliances.
