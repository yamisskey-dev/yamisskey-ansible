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

Install Ansible and tools:
```bash
make install
```

Create inventory (choose your target):
```bash
make inventory                    # Create servers inventory (default)
make inventory TARGET=appliances  # Create TrueNAS appliances inventory
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

## 🎯 Target Types

### Servers (Default - TARGET=servers)
- **Path**: `ansible/servers/`
- **Inventory**: `ansible/servers/inventory`
- **Use case**: Traditional server management, web services, applications

### Appliances (TARGET=appliances)
- **Path**: `ansible/appliances/`
- **Inventory**: `ansible/appliances/inventory`
- **Use case**: TrueNAS management, storage appliances

## 📋 Complete Provisioning Workflows

### New Server Setup

1. **Initial Setup**
   ```bash
   make install                    # Install Ansible via uv
   make inventory                  # Create servers inventory (default)
   make backup                     # Backup initial state
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
# Sequential deployment
make deploy PLAYBOOKS='common security modsecurity-nginx monitoring minio misskey'

# Or step by step with checks
make check PLAYBOOK=common
make run PLAYBOOK=common
make check PLAYBOOK=misskey
make run PLAYBOOK=misskey
```

### TrueNAS Appliance Setup

Complete TrueNAS appliance management:

```bash
# Initial setup
make inventory TARGET=appliances
make backup TARGET=appliances

# Deploy MinIO migration
make deploy PLAYBOOKS='setup migrate-minio-phase-a' TARGET=appliances

# Or step by step
make check PLAYBOOK=setup TARGET=appliances
make run PLAYBOOK=setup TARGET=appliances
make run PLAYBOOK=migrate-minio-truenas TARGET=appliances
```

### Mixed Environment Management

Managing both servers and appliances:

```bash
# Check servers
make list TARGET=servers
make run PLAYBOOK=common TARGET=servers

# Check appliances
make list TARGET=appliances
make run PLAYBOOK=setup TARGET=appliances

# Backup both
make backup TARGET=servers
make backup TARGET=appliances
```

## 📦 Available Playbooks

### Server Playbooks (`TARGET=servers`)

Available in `ansible/servers/playbooks/`:

**Essential Services**
- `common` - Base system configuration and essential packages
- `security` - Security hardening and firewall configuration
- `system-init` - System initialization
- `system-test` - System testing and validation
- `monitoring` - System monitoring and alerting setup

**Web Services**
- `modsecurity-nginx` - Nginx with ModSecurity WAF
- `misskey` - Misskey social media platform
- `misskey-proxy` - Misskey proxy configuration
- `ai` - AI services integration
- `searxng` - Privacy-respecting search engine
- `outline` - Team wiki and knowledge base
- `cryptpad` - Collaborative document editing

**Communication & Collaboration**
- `matrix` - Matrix homeserver
- `jitsi` - Video conferencing platform
- `stalwart` - Email server

**Storage & Database**
- `minio` - S3-compatible object storage
- `misskey-backup` - Backup automation for Misskey
- `borgbackup` - Backup solution

**Utilities & Services**
- `uptime` - Uptime monitoring
- `deeplx` - Translation service
- `mcaptcha` - Privacy-focused CAPTCHA
- `ctfd` - Capture The Flag platform
- `minecraft` - Minecraft server
- `vikunja` - Task management
- `lemmy` - Link aggregator
- `impostor` - Among Us server
- `zitadel` - Identity and access management

**Infrastructure & Operations**
- `clone-repos` - Repository cloning and setup
- `migrate` - Data migration tools
- `migrate-minio` - MinIO data migration
- `operations` - Operational tasks
- `export` / `import` - System backup and restore
- `cloudflared` - Cloudflare tunnel
- `cloudflare-warp` - Cloudflare WARP

### Appliance Playbooks (`TARGET=appliances`)

Available in `ansible/appliances/playbooks/`:

**TrueNAS Management**
- `setup` - Initial TrueNAS configuration
- `migrate-minio-truenas` - MinIO setup on TrueNAS
- `migrate-minio-phase-a` - Phase A of MinIO migration
- `migrate-minio-cutover` - MinIO migration cutover
- `truenas-minio-deploy-and-migrate` - Complete MinIO deployment and migration

## 🔧 Troubleshooting

### Check Status
```bash
make help                       # Show all available commands
make list                       # List server playbooks
make list TARGET=appliances     # List appliance playbooks
make logs                       # Check recent execution logs
```

### Backup and Recovery
```bash
# Create backups
make backup                     # Backup servers inventory
make backup TARGET=appliances   # Backup appliances inventory

# Check backup files
ls -la backups/
```

### Common Issues

1. **Playbook not found**: Use `make list [TARGET=target]` to see available playbooks
2. **Permission errors**: Ensure `--ask-become-pass` is working (built into run commands)
3. **Target confusion**: Remember to specify `TARGET=appliances` for TrueNAS operations
4. **Missing inventory**: Use `make inventory [TARGET=target]` to create inventory files

## 📁 File Structure

```
yamisskey-provision/
├── ansible/
│   ├── servers/                    # Server management
│   │   ├── playbooks/             # Server playbooks
│   │   ├── roles/                 # Server roles
│   │   └── inventory              # Server inventory (created by make inventory)
│   └── appliances/                # Appliance management
│       ├── playbooks/             # Appliance playbooks (TrueNAS)
│       ├── roles/                 # Appliance roles
│       └── inventory              # Appliance inventory (created by make inventory TARGET=appliances)
├── logs/                          # Execution logs
├── backups/                       # Inventory backups
│   ├── servers-inventory-*.bak    # Server inventory backups
│   └── appliances-inventory-*.bak # Appliance inventory backups
├── Makefile                       # Unified Ansible wrapper
└── README.md                      # This documentation
```

## 🚀 Advanced Usage

### Combining Parameters
```bash
# Run specific playbook with host limit and tags
make run PLAYBOOK=security LIMIT=local TAGS=firewall,ssh

# Check appliance configuration for specific tasks
make check PLAYBOOK=migrate-minio-phase-a TARGET=appliances LIMIT=truenas.local

# Deploy multiple playbooks with specific tags
make deploy PLAYBOOKS='common security' TAGS=install,config
```

### Quick Reference
```bash
# Most common commands
make help                                    # Get help
make install                                 # Install Ansible
make inventory                               # Setup servers
make inventory TARGET=appliances             # Setup appliances
make list                                    # List server playbooks
make list TARGET=appliances                  # List appliance playbooks
make run PLAYBOOK=common                     # Run server playbook
make run PLAYBOOK=setup TARGET=appliances    # Run appliance playbook
make backup                                  # Backup servers
make backup TARGET=appliances                # Backup appliances
```

This unified system provides consistent, predictable commands that work the same way whether you're managing traditional servers or TrueNAS appliances.