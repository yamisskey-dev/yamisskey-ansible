# yamisskey-provision

Modern Ansible infrastructure management with SOPS secrets management and Nix-based development environment.

## 🚀 Quick Start

### Prerequisites
- Make

### System Requirements
- Linux distribution providing a writable `systemd` (e.g. Ubuntu 22.04 LTS)
- Python 3 available as `/usr/bin/python3`, `ansible` will be installed via `uv`.

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