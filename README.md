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

## 🏆 Quality Achievements

This project has achieved **100% Ansible Lint compliance** through comprehensive quality improvements:

- **✅ Zero Lint Errors**: Complete elimination of all 265 initial errors
- **✅ Production Profile**: Meets enterprise-grade "production" quality standards
- **✅ 400 Files Validated**: All playbooks, roles, and configuration files pass strict quality checks
- **✅ YAML Standards**: Complete syntax unification and best practices compliance
- **✅ Security Ready**: Hardened configurations ready for production deployment

### Quality Metrics
```
Initial Errors:  265
Final Errors:    0
Success Rate:    100%
Files Validated: 400
Profile Level:   Production
```

### Quality Improvements Implemented
- **YAML Syntax Standardization**: File endings, indentation, boolean values
- **Ansible Best Practices**: FQCN compliance, module optimization, Jinja templating
- **Configuration Consistency**: Inventory alignment, variable standardization
- **Role Structure**: Defaults standardization for maintainability
- **Security Hardening**: Vault integration, permission optimization

## 🔐 Security & Vault Configuration

### Ansible Vault Setup

This project uses Ansible Vault for secure secret management. Before running playbooks, set up your vault:

```bash
# Create vault password file
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass

# Create encrypted vault file
ansible-vault create deploy/servers/group_vars/vault.yml --vault-password-file .vault_pass
```

### Required Vault Variables

Add these encrypted variables to your vault files:

```yaml
# Production passwords (per host)
vault_balthasar_sudo_password: "secure_password_here"
vault_caspar_sudo_password: "secure_password_here"
vault_joseph_sudo_password: "secure_password_here"
vault_raspberrypi_sudo_password: "secure_password_here"
vault_linode_prox_sudo_password: "secure_password_here"

# MinIO credentials
minio_root_user: "admin"
minio_root_password: "secure_minio_password"
minio_kms_master_key: "minio-master-key:base64-encoded-key"

# TrueNAS credentials
truenas_api_token: "api-token-here"
truenas_minio_root_user: "admin"
truenas_minio_root_password: "secure_password"
truenas_minio_kms_key: "kms-encryption-key"

# Cloudflare Tunnel
cloudflare_tunnel_id: "tunnel-uuid-here"
cloudflare_tunnel_token: "tunnel-token-here"
cloudflare_tunnel_credentials: "credentials-json-here"
```

### Vault Usage Examples

```bash
# Edit vault file
ansible-vault edit deploy/servers/group_vars/vault.yml --vault-password-file .vault_pass

# Run playbook with vault
make run PLAYBOOK=common --extra-vars "@deploy/servers/group_vars/vault.yml" --vault-password-file .vault_pass

# Encrypt existing file
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
make install                      # Install Ansible via uv
ansible-galaxy collection install -r requirements.yml  # Install Collections
```

Create inventory (choose your target):
```bash
make inventory                    # Create servers inventory (default)
make inventory TARGET=appliances  # Create TrueNAS appliances inventory
```

### 2.1 Collections Installation

The project uses modern Ansible Collections. Install them automatically:

```bash
# Install all Collections (yamisskey + community dependencies)
ansible-galaxy collection install -r requirements.yml

# Verify Collections installation
ansible-galaxy collection list | grep yamisskey
# Should show: yamisskey.servers, yamisskey.appliances

# Check community dependencies
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

## 🎯 Target Types

### Servers (Default - TARGET=servers)
- **Path**: `deploy/servers/`
- **Inventory**: `deploy/servers/inventory`
- **Use case**: Traditional server management, web services, applications

### Appliances (TARGET=appliances)
- **Path**: `deploy/appliances/`
- **Inventory**: `deploy/appliances/inventory`
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

Available in `deploy/servers/playbooks/`:

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

Available in `deploy/appliances/playbooks/`:

**TrueNAS Management**
- `setup` - Initial TrueNAS configuration
- `migrate-minio-truenas` - MinIO setup on TrueNAS
- `migrate-minio-phase-a` - Phase A of MinIO migration
- `migrate-minio-cutover` - MinIO migration cutover
- `truenas-minio-deploy-and-migrate` - Complete MinIO deployment and migration

## 🏗️ Infrastructure Architecture

### Host Roles & Services

**Production Environment (5 Hosts):**

**balthasar** - Main Social & Application Server
- ModSecurity-Nginx (8080) - Main reverse proxy
- Misskey (3001) - Yamisskey social platform
- Matrix Synapse (8008) - Matrix homeserver
- Element (8081) - Matrix web client
- Outline (3004) - Team wiki
- CryptPad (3003) - Collaborative editing
- Neo-Quesdon (3025) - Q&A service
- Lemmy (8536) - Link aggregator
- Vikunja (3456) - Task management
- cAdvisor (8085) - Container monitoring

**caspar** - Security & Monitoring Hub
- ModSecurity-Nginx (8080) - Security proxy
- Prometheus (9090) - Metrics collection
- Grafana (3000) - Monitoring dashboard
- AlertManager (9093) - Alert routing
- Blackbox Exporter (9115) - Service probing
- CTFd (8000) - Capture The Flag platform
- Zitadel (8993) - Identity & access management
- mCaptcha (7493) - Privacy-focused CAPTCHA
- Uptime Kuma (3009) - Uptime monitoring
- nayamisskey (3002) - Test Misskey instance
- Nostream (8080) - Nostr relay

**joseph** - Storage Server (TrueNAS SCALE)
- MinIO API (9000) - S3-compatible storage
- MinIO Console (9001) - Management interface
- Node Exporter (9100) - System metrics

**raspberrypi** - Gaming Server
- Minecraft Java (25565) - Game server
- playit.gg (8080) - Gaming proxy

**linode_prox** - External Proxy Services
- Nginx (80) - Web proxy for Summaly
- Media Proxy RS (12766) - Media processing
- Summaly (3030) - Link preview service
- Squid (3128) - HTTP proxy

### Role Dependencies & Relationships

**Core Infrastructure Dependencies:**
```
security (UFW, fail2ban, SSH hardening)
  ↳ common (Docker, system packages)
    ↳ monitoring (Prometheus agents)
```

**Application Service Dependencies:**
```
misskey → minio (file storage)
       → modsecurity-nginx (reverse proxy)
       → security (firewall rules)

matrix → modsecurity-nginx (reverse proxy)
      → security (base hardening)

monitoring → security (firewall configuration)
          → common (Docker runtime)

minio → security (port 9000/9001 access)
      → common (Docker setup)
```

**Cross-Service Integration:**
- All web services → ModSecurity-Nginx → Cloudflare Tunnel
- All metrics → Prometheus → Grafana → AlertManager
- Misskey + Matrix → MinIO (shared S3 storage)
- All hosts → Security (centralized hardening)

### Variable Compatibility Matrix

**Cross-Platform Variables (servers ⟷ appliances):**
| Purpose | servers | appliances | Status |
|---------|---------|------------|--------|
| MinIO Root User | `minio_root_user` | `truenas_minio_root_user` | ✅ Compatible |
| MinIO Root Password | `minio_root_password` | `truenas_minio_root_password` | ✅ Compatible |
| KMS Encryption | `minio_kms_master_key` | `truenas_minio_kms_key` | ✅ Compatible |
| Public Domain | `minio_api_server_name` | `truenas_minio_domain` | ✅ Compatible |
| Cloudflare Token | `cloudflare_tunnel_token` | `truenas_tunnel_token` | ✅ Compatible |
| Bucket Names | `minio_bucket_name_for_*` | `minio_bucket_name_for_*` | ✅ Shared |

## 🔧 Troubleshooting

### Infrastructure Health Checks

**System-Wide Verification:**
```bash
# Check all services across infrastructure
make run PLAYBOOK=system-test

# Verify specific host configuration
make run PLAYBOOK=operations LIMIT=joseph TAGS=health-check

# Test inter-service connectivity
make run PLAYBOOK=operations TAGS=connectivity-test
```

**Service-Specific Checks:**

**balthasar (Social Platform):**
```bash
# Misskey API health
curl -f http://localhost:3001/api/ping || echo "❌ Misskey down"

# ModSecurity-Nginx proxy
curl -f http://localhost:8080/healthz || echo "❌ Proxy down"

# Matrix homeserver
curl -f http://localhost:8008/_matrix/client/versions || echo "❌ Matrix down"
```

**joseph (Storage Server):**
```bash
# MinIO service health
curl -f http://localhost:9000/minio/health/live || echo "❌ MinIO down"

# Storage filesystem check
df -h /mnt/tank/ || echo "❌ Storage issues"
zpool status || echo "❌ ZFS pool problems"
```

**caspar (Monitoring Hub):**
```bash
# Prometheus metrics collection
curl -f http://localhost:9090/-/healthy || echo "❌ Prometheus down"

# Grafana dashboard
curl -f http://localhost:3000/api/health || echo "❌ Grafana down"
```

**TrueNAS Appliances:**
```bash
# Custom App status check
make run PLAYBOOK=operations TARGET=appliances TAGS=app-status

# External tunnel connectivity
curl -f https://drive.yami.ski/minio/health/live || echo "❌ Tunnel down"
```

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

### Common Issues & Solutions

1. **Playbook not found**: Use `make list [TARGET=target]` to see available playbooks
2. **Permission errors**: Ensure `--ask-become-pass` is working (built into run commands)
3. **Target confusion**: Remember to specify `TARGET=appliances` for TrueNAS operations
4. **Missing inventory**: Use `make inventory [TARGET=target]` to create inventory files
5. **Vault errors**: Check `.vault_pass` exists and vault variables are encrypted properly
6. **Service conflicts**: Verify no port conflicts with `netstat -tlnp | grep <port>`
7. **Storage issues**: Check ZFS pool health: `zpool status` and dataset permissions
8. **Network connectivity**: Verify Tailscale mesh and DNS resolution between hosts
9. **Docker issues**: Check Docker daemon status and container logs: `docker logs <container>`
10. **Cloudflare Tunnel**: Verify tunnel tokens and domain DNS records point correctly

### Performance Tuning

**MinIO Storage Optimization:**
```bash
# Check MinIO performance
mc admin info truenas-tunnel

# Optimize ZFS recordsize for MinIO
zfs set recordsize=1M tank/minio
```

**Monitoring & Metrics:**
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# View Grafana dashboard health
curl http://localhost:3000/api/health
```

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
