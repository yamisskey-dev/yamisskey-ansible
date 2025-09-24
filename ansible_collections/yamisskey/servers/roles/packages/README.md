# Packages Role - Flexible Package Management

This role provides a flexible and efficient way to manage system packages across 40+ roles using role-based, tag-based, and profile-based package selection.

## Features

- **Role-based packages**: Each role can define its required packages
- **Tag-based packages**: Install packages based on Ansible tags
- **Profile-based packages**: Predefined package sets for different environments
- **Multiple installation methods**: Support for various package installation methods
- **Base packages**: Essential packages always installed
- **Extra packages**: Additional packages specified at runtime
- **Automatic deduplication**: No duplicate packages installed
- **YAML syntax compliant**: Clean, readable configuration

## Installation Methods

The packages role supports multiple installation methods:

### 1. Standard APT Packages
Standard packages available in the default Debian/Ubuntu repositories.

### 2. APT Repositories
Packages from external APT repositories with GPG key management.

### 3. Manual Downloads
Binary downloads from GitHub releases and other sources.

### 4. Python Packages
Python packages installed via pip.

### 5. Manual Scripts
Custom installation scripts for complex packages.

## Usage Examples

### 1. Role-based Package Installation

When a role is included, its packages are automatically installed:

```yaml
# In a playbook
- name: Setup Misskey server
  hosts: servers
  roles:
    - yamisskey.servers.misskey  # Installs: nodejs, npm, postgresql-client, redis-tools
    - yamisskey.servers.nginx    # Installs: nginx, nginx-module-headers-more
    - yamisskey.servers.redis    # Installs: redis-server, redis-tools
```

### 2. Tag-based Package Installation

Install packages based on tags:

```yaml
# Run with specific tags
ansible-playbook -i inventory playbook.yml --tags "web,database,monitoring"

# This will install:
# - web: nginx, apache2
# - database: postgresql, mysql-server, redis-server  
# - monitoring: prometheus, grafana, node-exporter
```

### 3. Profile-based Package Installation

Use predefined profiles for different environments:

```yaml
# In group_vars or host_vars
packages_profile: "development"  # or "server", "ai-server"

# Development profile includes:
# - ansible, ansible-lint, yamllint, sops, age, gnupg
# - docker.io, docker-compose, python3-passlib
# - git, ghq, vim, nano, tree
```

### 4. Extra Packages

Add additional packages at runtime:

```yaml
# In group_vars or host_vars
packages_extra:
  - vim
  - nano
  - tree
  - htop
```

### 5. Combined Usage

```yaml
# In group_vars/servers.yml
packages_profile: "server"
packages_extra:
  - custom-package
  - another-tool

# In playbook
- name: Setup production server
  hosts: servers
  roles:
    - yamisskey.servers.common
    - yamisskey.servers.security
    - yamisskey.servers.monitor
  tags:
    - security
    - monitoring
```

## Configuration

### Role-based Packages

Add packages for specific roles in `defaults/main.yml`:

```yaml
packages_by_role:
  your_role:
    Debian:
      - package1
      - package2
    RedHat:
      - package1
      - package2
```

### Tag-based Packages

Define packages for tags:

```yaml
packages_by_tag:
  your_tag:
    Debian:
      - package1
      - package2
```

### Profile-based Packages

Create new profiles:

```yaml
packages_profiles:
  your_profile:
    Debian:
      - package1
      - package2
```

## Available Roles with Packages

### Core System
- `common`: prometheus, rclone, apparmor, auditd, tor, golang
- `security`: fail2ban, ufw, dnscrypt-proxy, clamav
- `system_init`: cloudflared, tailscale, docker.io, docker-compose
- `watch`: prometheus-node-exporter
- `monitor`: prometheus, grafana, node-exporter

### Applications
- `misskey`: docker.io, docker-compose, postgresql-client, redis-tools
- `misskey_proxy`: nginx, certbot, python3-certbot-nginx
- `misskey_backup`: rclone, postgresql-client, redis-tools
- `minio`: docker.io, docker-compose
- `matrix`: docker.io, docker-compose, postgresql-client, redis-tools

### AI/ML
- `ai`: mecab, mecab-ipadic, python3, python3-pip, python3-dev, python3-venv

### Development
- `ghq`: ghq

### Infrastructure
- `cloudflared`: cloudflared
- `cloudflare_warp`: cloudflare-warp

### Web Services
- `modsecurity_nginx`: nginx, libapache2-mod-security2, nginx-module-headers-more

### Databases (if needed)
- `postgresql`: postgresql, postgresql-client, postgresql-contrib
- `mysql`: mysql-server, mysql-client
- `redis`: redis-server, redis-tools

### Monitoring
- `grafana`: grafana
- `prometheus`: prometheus, prometheus-node-exporter

### Testing
- `integration_test`: python3-pytest, python3-tox, docker.io
- `system_test`: docker.io, curl, jq

### Utilities
- `backup`: rclone, rsync, tar, gzip
- `tools`: curl, wget, git, htop, btop, jq, yq

### Application-specific Roles
- `minecraft`: docker.io, docker-compose, playit
- `jitsi`: docker.io, docker-compose, nginx
- `lemmy`: docker.io, docker-compose, postgresql-client
- `searxng`: docker.io, docker-compose
- `outline`: docker.io, docker-compose, postgresql-client
- `vikunja`: docker.io, docker-compose, postgresql-client
- `cryptpad`: docker.io, docker-compose
- `ctfd`: docker.io, docker-compose, python3, python3-pip
- `neo_quesdon`: docker.io, docker-compose
- `mcaptcha`: docker.io, docker-compose
- `deeplx`: docker.io, docker-compose
- `impostor`: docker.io, docker-compose
- `uptime`: docker.io, docker-compose
- `stalwart`: docker.io, docker-compose
- `zitadel`: docker.io, docker-compose
- `operations`: docker.io, docker-compose
- `migrate`: docker.io, docker-compose, rclone
- `migrate_minio`: docker.io, docker-compose, rclone, mc
- `migration_validator`: docker.io, docker-compose, curl, jq
- `export`: docker.io, docker-compose, rclone
- `import`: docker.io, docker-compose, rclone
- `compat`: docker.io, docker-compose

## Available Tags

### System Tags
- `always`: curl, wget, git
- `packages`: apt-transport-https, ca-certificates, gnupg, lsb-release

### Security Tags
- `security`: fail2ban, ufw, clamav
- `hardening`: fail2ban, ufw, clamav, apparmor, auditd

### Monitoring Tags
- `monitoring`: prometheus, grafana, prometheus-node-exporter
- `prometheus`: prometheus, prometheus-node-exporter
- `node_exporter`: prometheus-node-exporter
- `cadvisor`: docker.io
- `system`: htop, btop, sysstat, lynis

### Infrastructure Tags
- `infrastructure`: docker.io, docker-compose
- `docker`: docker.io, docker-compose

### Web Service Tags
- `proxy`: nginx, certbot, python3-certbot-nginx
- `nginx`: nginx, nginx-module-headers-more
- `reverse-proxy`: nginx, certbot, python3-certbot-nginx
- `ssl`: certbot, python3-certbot-nginx

### Storage Tags
- `storage`: rclone, rsync
- `minio`: docker.io, docker-compose
- `object-storage`: docker.io, docker-compose
- `backup`: rclone, rsync, tar, gzip

### Development Tags
- `development`: ghq, git, vim, nano
- `git`: git, ghq
- `repository`: git, ghq
- `yamisskey`: docker.io, docker-compose, postgresql-client, redis-tools

### Application Tags
- `misskey`: docker.io, docker-compose, postgresql-client, redis-tools
- `minecraft`: docker.io, docker-compose, playit
- `papermc`: docker.io, docker-compose, playit
- `geyser`: docker.io, docker-compose, playit
- `floodgate`: docker.io, docker-compose, playit

### Testing Tags
- `test`: python3-pytest, python3-tox, docker.io
- `connectivity`: curl, jq, nmap
- `validation`: curl, jq
- `migration`: docker.io, docker-compose, rclone
- `services`: docker.io, docker-compose

### Performance Tags
- `perf`: htop, btop, sysstat

### Application-specific Tags
- `app`: docker.io, docker-compose
- `service`: docker.io, docker-compose
- `info`: curl, jq

## Available Profiles

- `development`: Development tools and utilities (ansible, ansible-lint, yamllint, sops, age, gnupg, docker.io, docker-compose, python3-passlib, git, ghq, vim, nano, tree, htop, btop, jq, yq)
- `server`: Production server essentials (prometheus, rclone, apparmor, auditd, fail2ban, ufw, cloudflared, tailscale, docker.io, docker-compose, nginx, postgresql-client, redis-tools)
- `ai-server`: AI/ML development environment (mecab, mecab-ipadic, python3, python3-pip, python3-dev, python3-venv, docker.io, docker-compose, htop, btop, jq, yq)
- `monitoring`: Monitoring stack (prometheus, grafana, prometheus-node-exporter, docker.io, docker-compose, htop, btop, sysstat)
- `storage`: Storage and backup tools (rclone, rsync, tar, gzip, docker.io, docker-compose, postgresql-client, redis-tools)

## Benefits

1. **Scalable**: Easy to add new roles and packages
2. **Flexible**: Multiple selection methods (role, tag, profile)
3. **Efficient**: Automatic deduplication and smart selection
4. **Maintainable**: Clean YAML structure, easy to read and modify
5. **Compatible**: Works with existing Ansible patterns
6. **Debuggable**: Detailed logging of package selection process

## Debugging

The role provides detailed output showing:
- Active profile
- Active roles
- Active tags
- Selected packages
- Installation results

Use `-v` or `--verbose` for more detailed output.
