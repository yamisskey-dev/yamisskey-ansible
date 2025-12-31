# ghq Role

This role installs and configures [ghq](https://github.com/x-motemen/ghq) for Git repository management, specifically designed for yamisskey-dev projects.

## Features

- Install ghq via package manager or go install
- Configure ghq with custom root directory (`~/.ghq`)
- Clone yamisskey-dev repositories
- Update existing repositories
- List managed repositories

## Requirements

- Ansible 2.9+
- Ubuntu 20.04+ or Debian 11+
- Git (for repository operations)

## Role Variables

### Default Variables

```yaml
# ghq configuration
ghq_root: "~/.ghq"
ghq_github_remote: "https://github.com/"

# yamisskey-dev repositories to manage
yamisskey_repositories:
  - "yamisskey-dev/yamisskey"
  - "yamisskey-dev/yamisskey-assets"
  - "yamisskey-dev/yui"
  - "yamisskey-dev/yamisskey-backup"
  - "yamisskey-dev/yamisskey-anonote"
  - "yamisskey-dev/ctf.yami.ski"

# ghq operations
ghq_operation: "install"  # install, clone, update, list
ghq_update: false
ghq_force: false

# ghq installation
ghq_install_method: "package"  # package, go, binary
ghq_version: "latest"
```

## Usage

### Install ghq

```yaml
- name: Install ghq
  include_role:
    name: yamisskey.servers.ghq
  vars:
    ghq_operation: "install"
```

### Clone repositories

```yaml
- name: Clone yamisskey-dev repositories
  include_role:
    name: yamisskey.servers.ghq
  vars:
    ghq_operation: "clone"
    yamisskey_repositories:
      - "yamisskey-dev/yamisskey"
      - "yamisskey-dev/yamisskey-assets"
```

### Update repositories

```yaml
- name: Update yamisskey-dev repositories
  include_role:
    name: yamisskey.servers.ghq
  vars:
    ghq_operation: "update"
```

### List repositories

```yaml
- name: List managed repositories
  include_role:
    name: yamisskey.servers.ghq
  vars:
    ghq_operation: "list"
```

## Installation Methods

### Package Manager (Default)

```yaml
ghq_install_method: "package"
```

### Go Install

```yaml
ghq_install_method: "go"
```

## Directory Structure

After installation, repositories will be organized as:

```
~/.ghq/
├── github.com/
│   └── yamisskey-dev/
│       ├── yamisskey/
│       ├── yamisskey-assets/
│       ├── yui/
│       ├── yamisskey-backup/
│       ├── yamisskey-anonote/
│       └── ctf.yami.ski/
```

## Dependencies

None.

## Example Playbook

```yaml
---
- name: Setup ghq for yamisskey-dev development
  hosts: development
  become: true
  roles:
    - role: yamisskey.servers.ghq
      vars:
        ghq_operation: "install"

    - role: yamisskey.servers.ghq
      vars:
        ghq_operation: "clone"
```

## License

MIT

## Author Information

yamisskey-dev
