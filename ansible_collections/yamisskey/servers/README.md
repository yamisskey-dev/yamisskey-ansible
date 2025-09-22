# yamisskey.servers Ansible Collection

Enterprise-grade server infrastructure automation collection for Misskey, MinIO, monitoring, and supporting services. Optimized for Linux server environments with Docker-based deployments.

## 🚀 Install & Use (Quick)
```bash
# From Galaxy
ansible-galaxy collection install yamisskey.servers

# Or from local tarball
ansible-galaxy collection install dist/servers/yamisskey-servers-*.tar.gz
```

## 🎯 Overview

This collection provides production-ready Ansible roles for deploying and managing a complete Misskey social media platform infrastructure, including storage, security, monitoring, and backup solutions.

## 📦 Installation

### From Built Package
```bash
ansible-galaxy collection install dist/servers/yamisskey-servers-1.0.0.tar.gz
```

### From Requirements File
```yaml
# requirements.yml
collections:
  - name: yamisskey.servers
    source: ./dist/servers/yamisskey-servers-1.0.0.tar.gz
    type: file
```

```bash
ansible-galaxy collection install -r requirements.yml
```

## 🏗️ Available Roles

### Core Infrastructure
- **`common`** - Base system packages and essential tools
- **`security`** - Security hardening and monitoring setup
- **`minio`** - S3-compatible object storage service
- **`compat`** - Docker Compose compatibility layer

### Services & Applications
- **`misskey`** - Misskey social media platform
- **`misskey-proxy`** - Reverse proxy configuration for Misskey
- **`monitor`** - Prometheus and Grafana monitoring stack

## 🚀 Usage Examples

### Quick Start - Core Infrastructure
```yaml
---
- name: Deploy Core Infrastructure
  hosts: servers
  become: true
  roles:
    - yamisskey.servers.common
    - yamisskey.servers.security
    - yamisskey.servers.minio
```

### Complete Misskey Stack
```yaml
---
- name: Deploy Complete Misskey Stack
  hosts: misskey_servers
  become: true
  roles:
    - yamisskey.servers.common
    - yamisskey.servers.security
    - yamisskey.servers.minio
    - yamisskey.servers.misskey
    - yamisskey.servers.monitor
```

### Using Collection Playbooks
```bash
# Test core infrastructure roles
ansible-playbook yamisskey.servers.test-core-infrastructure

# Deploy complete stack
ansible-playbook yamisskey.servers.deploy-misskey-stack

# Deploy proxy services
ansible-playbook yamisskey.servers.deploy-proxy-services
```

## 🔗 Dependencies

This collection automatically manages the following dependencies:

- `community.docker >= 3.0.0` - Docker container management
- `community.sops >= 1.6.0` - Secret management with SOPS
- `ansible.posix >= 1.5.0` - POSIX system utilities

## ⚙️ Configuration

### Host Variables
```yaml
# Enable optional features
enable_monitoring: true
enable_backup: true

# MinIO configuration
minio_root_user: "admin"
minio_root_password: "{{ vault_minio_password }}"

# Misskey configuration
misskey_domain: "example.social"
misskey_db_password: "{{ vault_misskey_db_password }}"
```

### Inventory Groups
```ini
[misskey_servers]
server1.example.com

[storage_servers]
storage1.example.com

[proxy_servers]
proxy1.example.com
```

## 🛡️ Security Features

- Automated security updates via `unattended-upgrades`
- Fail2ban intrusion detection system
- System audit logging with `auditd`
- AppArmor security profiles

## 📊 Monitoring & Observability

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards
- **Node Exporter**: System metrics
- **Docker monitoring**: Container metrics
- **Application metrics**: Misskey-specific monitoring

## 🔄 Backup Strategy

- **Automated scheduling**: Configurable backup intervals
- **Remote storage**: Support for various backup destinations
- **Compression**: Efficient storage utilization
- **Verification**: Automatic backup integrity checks

## 🏷️ Tags

Roles support granular execution via tags:

```bash
# Security hardening only
ansible-playbook playbook.yml --tags security

# Storage setup only
ansible-playbook playbook.yml --tags minio,storage

# Monitoring setup only
ansible-playbook playbook.yml --tags monitoring
```

## 🔧 Development

### Building the Collection
```bash
ansible-galaxy collection build ansible_collections/yamisskey/servers/
```

### Running Tests
```bash
# Syntax check deploy playbooks
ansible-playbook -i 'localhost,' -c local deploy/servers/playbooks/test-core-infrastructure.yml --syntax-check

# Sanity tests for the collection
cd ansible_collections/yamisskey/servers && ansible-test sanity --python 3.11 -v
```

## 📋 Requirements

- **Ansible**: >= 2.10
- **Python**: >= 3.6
- **Operating Systems**:
  - Ubuntu 20.04+ (Focal)
  - Ubuntu 22.04+ (Jammy)
  - Debian 11+ (Bullseye)
  - Debian 12+ (Bookworm)

## 🤝 Support

- **Repository**: [yamisskey-provision](https://github.com/yamisskey-dev/yamisskey-provision)
- **Issues**: [GitHub Issues](https://github.com/yamisskey-dev/yamisskey-provision/issues)
- **Documentation**: See individual role documentation in `roles/*/README.md`

## 📄 License

MIT License - see the project repository for details.

## 🎉 Quality Assurance

- ✅ **100% Ansible Lint Compliance**: All roles pass production linting standards
- ✅ **Production Profile**: Enterprise-grade configurations and best practices
- ✅ **Dependency Management**: Automatic resolution of all required collections
- ✅ **Cross-Platform**: Tested on multiple Ubuntu and Debian versions
- ✅ **Documentation**: Comprehensive role and playbook documentation

---

**yamisskey.servers v1.0.0** - Enterprise Infrastructure Automation
