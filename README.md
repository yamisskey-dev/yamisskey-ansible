# yamisskey-provision

A flexible Ansible infrastructure management toolkit with an intuitive Makefile wrapper for deploying and managing Misskey instances and related services.

## Overview

This repository provides a comprehensive infrastructure-as-code solution with:
- **Flexible Ansible Wrapper**: Advanced Makefile-based Ansible abstraction
- **Preset Configurations**: Pre-defined deployment scenarios (development, production, minimal, update)
- **Comprehensive Logging**: Automatic logging with cleanup and backup features
- **Environment Integration**: Seamless environment variable to Ansible variable conversion
- **Multi-Service Support**: Playbooks for Misskey, MinIO, monitoring, security, and more

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
make install-ansible
```

Create inventory:
```bash
make sv-inventory
```

### 3. Basic Usage

Run a playbook:
```bash
make run PLAYBOOK=common
```

Check what would be changed (dry-run):
```bash
make check PLAYBOOK=security
```

## Makefile Commands

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `run` | Execute any playbook with advanced options | `make run PLAYBOOK=common` |
| `check` | Dry-run with diff preview | `make check PLAYBOOK=security` |
| `syntax` | Syntax validation | `make syntax PLAYBOOK=misskey` |
| `list` | Show available playbooks and presets | `make list` |
| `deploy` | Run multiple playbooks in sequence | `make deploy PLAYBOOKS='common security'` |

### Management Commands

| Command | Description | Example |
|---------|-------------|---------|
| `logs` | View recent execution logs | `make logs` |
| `logs-clean` | Clean old logs (keep 7 days) | `make logs-clean` |
| `backup` | Backup current inventory | `make backup` |
| `restore` | Restore from backup | `make restore BACKUP_FILE=inventory-20231201.bak` |

### Setup Commands

| Command | Description | Notes |
|---------|-------------|-------|
| `install-ansible` | Install Ansible via uv | Cross-platform Python tool management |
| `sv-inventory` | Create basic local inventory | Edit manually for multi-host setups |
| `ap-inventory` | Create appliances inventory skeleton | For TrueNAS integration |

## Deployment Presets

Use presets for consistent deployment environments:

| Preset | Description | Tags | Extra Variables |
|--------|-------------|------|------------------|
| `development` | Development environment | install,config | debug_mode=true, force_recreate=true |
| `production` | Production environment | install,config,security | debug_mode=false |
| `minimal` | Minimal installation | install | skip optional tasks |
| `update` | Update existing setup | update,config | force_recreate=false |

### Usage Examples

```bash
# Production deployment
make run PLAYBOOK=misskey PRESET=production

# Development with specific host
make run PLAYBOOK=security LIMIT=local PRESET=development

# Minimal installation
make run PLAYBOOK=common PRESET=minimal
```

## Environment Variables

Configure behavior via environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `HOST_SERVICES` | Comma-separated services to manage | `HOST_SERVICES='nginx,redis'` |
| `DEBUG_MODE` | Enable debug output | `DEBUG_MODE=true` |
| `FORCE_RECREATE` | Force recreation of resources | `FORCE_RECREATE=true` |
| `BACKUP_RETENTION` | Number of backups to keep | `BACKUP_RETENTION=30` |
| `SKIP_TAGS` | Skip specific tags | `SKIP_TAGS='optional,docs'` |
| `ONLY_TAGS` | Run only specific tags | `ONLY_TAGS='install,config'` |

### Advanced Examples

```bash
# Production deployment with specific services
HOST_SERVICES='nginx,redis' make run PLAYBOOK=web PRESET=production

# Development setup with debug
DEBUG_MODE=true FORCE_RECREATE=true make run PLAYBOOK=misskey

# Custom tags
make run PLAYBOOK=security EXTRA='--tags install,config --skip-tags optional'
```

## Complete Provisioning Workflows

### New Server Setup

1. **Initial Setup**
   ```bash
   make install-ansible
   make sv-inventory
   make backup  # Backup initial state
   ```

2. **Base System Configuration**
   ```bash
   make run PLAYBOOK=common PRESET=production
   make run PLAYBOOK=security PRESET=production
   ```

3. **Service Installation**
   ```bash
   make run PLAYBOOK=monitoring PRESET=production
   make run PLAYBOOK=minio PRESET=production
   make run PLAYBOOK=misskey PRESET=production
   ```

### Misskey Instance Deployment

Complete Misskey setup workflow:

```bash
# Sequential deployment
make deploy PLAYBOOKS='common security modsecurity-nginx monitoring minio misskey' PRESET=production

# Or step by step with checks
make check PLAYBOOK=common PRESET=production
make run PLAYBOOK=common PRESET=production
make check PLAYBOOK=misskey PRESET=production
make run PLAYBOOK=misskey PRESET=production
```

### Development Environment

```bash
# Development setup with debug
make deploy PLAYBOOKS='common misskey' PRESET=development

# Quick iteration
DEBUG_MODE=true make run PLAYBOOK=misskey PRESET=development
```

### Service Management

```bash
# Individual service updates
make run PLAYBOOK=monitoring PRESET=update
make run PLAYBOOK=minio PRESET=update

# Check service configurations
make check PLAYBOOK=nginx PRESET=production
```

## Available Playbooks

Core infrastructure playbooks available in `ansible/servers/playbooks/`:

### Essential Services
- `common` - Base system configuration and essential packages
- `security` - Security hardening and firewall configuration
- `monitoring` - System monitoring and alerting setup

### Web Services
- `modsecurity-nginx` - Nginx with ModSecurity WAF
- `misskey` - Misskey social media platform
- `ai` - AI services integration
- `searxng` - Privacy-respecting search engine

### Storage & Database
- `minio` - S3-compatible object storage
- `misskey-backup` - Backup automation for Misskey

### Communication & Collaboration
- `matrix` - Matrix homeserver
- `jitsi` - Video conferencing platform
- `cryptpad` - Collaborative document editing
- `outline` - Team wiki and knowledge base

### Utilities & Games
- `uptime` - Uptime monitoring
- `deeplx` - Translation service
- `mcaptcha` - Privacy-focused CAPTCHA
- `ctfd` - Capture The Flag platform
- `minecraft` - Minecraft server
- `vikunja` - Task management
- `lemmy` - Link aggregator

### Infrastructure
- `clone-repos` - Repository cloning and setup
- `migrate` - Data migration tools
- `export` / `import` - System backup and restore

## Troubleshooting

### Check Logs
```bash
make logs                    # Recent logs
make logs-all               # All log files
```

### Backup and Recovery
```bash
make backup                 # Create inventory backup
make logs                  # Check for errors
make restore BACKUP_FILE=inventory-20231201.bak  # Restore if needed
```

### Common Issues

1. **Playbook not found**: Use `make list` to see available playbooks
2. **Permission errors**: Ensure user has sudo access
3. **Network issues**: Check Tailscale connectivity
4. **Ansible errors**: Check logs with `make logs`

## File Locations

- **Playbooks**: `ansible/servers/playbooks/`
- **Inventory**: `ansible/servers/inventory`
- **Logs**: `logs/`
- **Backups**: `backups/`

## Advanced Usage

For detailed information on advanced features:
```bash
make help-advanced
```

This includes complex examples, environment variable details, and expert tips for infrastructure management.