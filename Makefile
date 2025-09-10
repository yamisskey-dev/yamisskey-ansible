.PHONY: all install inventory clone migrate test provision help

DESTINATION_SSH_USER=$(shell whoami)
DESTINATION_HOSTNAME=$(shell hostname)
DESTINATION_IP=$(shell tailscale status | grep $(DESTINATION_HOSTNAME) | awk '{print $$1}')
DESTINATION_SSH_PORT=22
OS=$(shell lsb_release -is | tr '[:upper:]' '[:lower:]')
USER=$(shell whoami)
ENV_FILE=.env
APPLIANCES_DIR=ansible/appliances
SERVERS_DIR=ansible/servers
APPLIANCES_INV=$(APPLIANCES_DIR)/inventory
SERVERS_INV=$(SERVERS_DIR)/inventory
APPLIANCES_PLAY=$(APPLIANCES_DIR)/playbooks
SERVERS_PLAY=$(SERVERS_DIR)/playbooks

# Load environment variables if .env file exists
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export $(shell sed 's/=.*//' $(ENV_FILE))
endif

# Appliances helpers
.PHONY: ap-setup ap-migrate ap-e2e ap-syntax

ap-inventory:
	@echo "Appliances inventory path: $(APPLIANCES_INV)"
	@{ \
	  if [ -f "$(APPLIANCES_INV)" ]; then \
	    echo "Preview (first 20 lines):"; \
	    sed -n '1,20p' $(APPLIANCES_INV); \
	  else \
	    echo "# Creating skeleton appliances inventory"; \
	    mkdir -p $(dir $(APPLIANCES_INV)); \
	    echo "[truenas]" > $(APPLIANCES_INV); \
	    echo "truenas.local" >> $(APPLIANCES_INV); \
	    echo "Created skeleton at $(APPLIANCES_INV). Edit as needed."; \
	  fi; \
	}

ap-setup:
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles \
	ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/setup.yml --ask-become-pass

ap-migrate:
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles \
	ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-truenas.yml --ask-become-pass

ap-e2e:
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles \
	ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/truenas-minio-deploy-and-migrate.yml --ask-become-pass

ap-syntax:
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/setup.yml || true
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/truenas-minio-deploy-and-migrate.yml || true
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-truenas.yml
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-phase-a.yml
	@ANSIBLE_ROLES_PATH=$(APPLIANCES_DIR)/roles ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-cutover.yml

all: sv-inventory sv-provision

# Install Ansible itself (prerequisite for other operations)
install-ansible:
	@echo "📦 Installing Ansible and development tools via uv..."
	@echo "🖥️ Target OS: $(OS)"
	@echo ""
	@echo "🔧 Installing uv if not present..."
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "📦 Installing uv..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	fi
	@echo "✅ uv is available"
	@echo ""
	@echo "📋 Installing Python tools via uv..."
	@export PATH="$$HOME/.local/bin:$$PATH"; \
	uv tool install ansible; \
	uv tool install ansible-lint
	@echo "✅ Ansible tools installation completed"
	@echo ""
	@echo "📋 Installing git via package manager..."
	@if [ "$(OS)" = "ubuntu" ] || [ "$(OS)" = "debian" ] || [ "$(OS)" = "kali" ]; then \
		sudo apt-get update && sudo apt-get install -y git; \
	elif [ "$(OS)" = "arch" ]; then \
		sudo pacman -Syu --noconfirm git; \
	elif [ "$(OS)" = "gentoo" ]; then \
		sudo emerge dev-vcs/git; \
	else \
		echo "⚠️  Unsupported OS for git installation: $(OS)"; \
		echo "📋 Please install git manually"; \
	fi
	@echo "✅ Git installation completed"
	@echo ""
	@echo "📋 Installing Ansible collections..."
	@export PATH="$$HOME/.local/bin:$$PATH"; \
	ansible-galaxy collection install -r $(SERVERS_DIR)/requirements.yml
	@echo "🎉 Ready to run Ansible playbooks!"
	@echo ""
	@echo "Installed tools:"
	@echo "  - ansible (latest from PyPI)"
	@echo "  - ansible-lint (latest from PyPI)"
	@echo "  - git (from system package manager)"
	@echo ""
	@echo "Next steps:"
	@echo "1. Run: make sv-inventory"
	@echo "2. Run: ansible-playbook -i $(SERVERS_INV) $(SERVERS_PLAY)/system-init.yml --ask-become-pass"

# System initialization (Ansible itself managed by Makefile, other packages by playbook)
sv-install:
	@echo "📦 System initialization starting..."
	@echo ""
	@echo "🔧 Step 1: Installing Ansible and development tools..."
	@$(MAKE) install-ansible
	@echo ""
	@echo "🔧 Step 2: Running system initialization playbook..."
	@export PATH="$$HOME/.local/bin:$$PATH"; \
	ansible-playbook -i $(SERVERS_INV) $(SERVERS_PLAY)/system-init.yml --ask-become-pass
	@echo ""
	@echo "🎉 System initialization completed!"

sv-inventory:
	@echo "Creating inventory file..."
	@if [ "$(MODE)" = "migration" ] || ([ -n "$(SOURCE)" ] && [ -n "$(TARGET)" ]); then \
		echo "Creating migration inventory for $(SOURCE) → $(TARGET)..."; \
		SOURCE_IP=$$(tailscale status 2>/dev/null | grep "$(SOURCE)" | awk '{print $$1}' | head -1 || echo "$(SOURCE)"); \
		TARGET_IP=$$(tailscale status 2>/dev/null | grep "$(TARGET)" | awk '{print $$1}' | head -1 || echo "$(TARGET)"); \
		CURRENT_HOST=$$(hostname); \
		echo "[source_hosts]" > $(SERVERS_INV); \
		if [ "$$CURRENT_HOST" = "$(SOURCE)" ]; then \
			echo "$(SOURCE) ansible_connection=local" >> $(SERVERS_INV); \
		else \
			echo "$(SOURCE) ansible_host=$(SOURCE) ansible_user=$(USER)" >> $(SERVERS_INV); \
		fi; \
		echo "" >> $(SERVERS_INV); \
		echo "[target_hosts]" >> $(SERVERS_INV); \
		if [ "$$CURRENT_HOST" = "$(TARGET)" ]; then \
			echo "$(TARGET) ansible_connection=local" >> $(SERVERS_INV); \
		else \
			echo "$(TARGET) ansible_host=$(TARGET) ansible_user=$(USER)" >> $(SERVERS_INV); \
		fi; \
		echo "" >> $(SERVERS_INV); \
		echo "# Migration mode aliases for compatibility" >> $(SERVERS_INV); \
		echo "[source:children]" >> $(SERVERS_INV); \
		echo "source_hosts" >> $(SERVERS_INV); \
		echo "" >> $(SERVERS_INV); \
		echo "[destination:children]" >> $(SERVERS_INV); \
		echo "target_hosts" >> $(SERVERS_INV); \
		echo "" >> $(SERVERS_INV); \
		echo "[all:vars]" >> $(SERVERS_INV); \
		echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ProxyCommand=\"tailscale nc %h %p\"'" >> $(SERVERS_INV); \
		echo "ansible_python_interpreter=/usr/bin/python3" >> $(SERVERS_INV); \
		echo "ansible_ssh_pipelining=true" >> $(SERVERS_INV); \
		echo "ansible_become=true" >> $(SERVERS_INV); \
		echo "ansible_become_method=sudo" >> $(SERVERS_INV); \
		echo "ansible_become_user=root" >> $(SERVERS_INV); \
		echo "Migration inventory created at $(SERVERS_INV)"; \
		echo "Source: $(SOURCE) ($$SOURCE_IP)"; \
		echo "Target: $(TARGET) ($$TARGET_IP)"; \
	else \
		echo "Creating standard inventory..."; \
		CURRENT_HOST=$$(hostname); \
		echo "[source]" > $(SERVERS_INV); \
		echo "$$CURRENT_HOST ansible_connection=local" >> $(SERVERS_INV); \
		echo "" >> $(SERVERS_INV); \
		echo "[destination]" >> $(SERVERS_INV); \
		if [ "$$CURRENT_HOST" != "$(DESTINATION_HOSTNAME)" ]; then \
			echo "$(DESTINATION_HOSTNAME) ansible_host=$(DESTINATION_IP) ansible_user=$(DESTINATION_SSH_USER) ansible_port=$(DESTINATION_SSH_PORT)" >> $(SERVERS_INV); \
		else \
			echo "$$CURRENT_HOST ansible_connection=local" >> $(SERVERS_INV); \
		fi; \
		echo "" >> $(SERVERS_INV); \
		echo "[all:vars]" >> $(SERVERS_INV); \
		echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10'" >> $(SERVERS_INV); \
		echo "ansible_python_interpreter=/usr/bin/python3" >> $(SERVERS_INV); \
		echo "ansible_ssh_pipelining=true" >> $(SERVERS_INV); \
		echo "ansible_become=true" >> $(SERVERS_INV); \
		echo "ansible_become_method=sudo" >> $(SERVERS_INV); \
		echo "ansible_become_user=root" >> $(SERVERS_INV); \
		echo "Standard inventory created at $(SERVERS_INV)"; \
		echo "Source: $$CURRENT_HOST (local)"; \
		echo "Destination: $(DESTINATION_HOSTNAME) ($(DESTINATION_IP))"; \
	fi

# Repository cloning (migrated to clone-repos.yml)
sv-clone:
	@echo "📁 Repository cloning has been migrated to Ansible playbook"
	@echo "Run: ansible-playbook -i $(SERVERS_INV) $(SERVERS_PLAY)/clone-repos.yml"

sv-migrate:
	@echo "🚀 Migrating MinIO data with encryption and progress monitoring..."
	@echo ""
	@echo "📋 Usage examples:"
	@echo "  make migrate                           # Default: source→destination"
	@echo "  make migrate SOURCE=balthasar TARGET=raspberrypi  # Custom hosts"
	@echo ""
	@if [ -n "$(SOURCE)" ] && [ -n "$(TARGET)" ]; then \
		echo "🔧 Creating migration inventory and executing..."; \
		echo "📡 Source: $(SOURCE)"; \
		echo "🎯 Target: $(TARGET)"; \
		echo "🌐 Network: Tailscale private network"; \
		echo ""; \
		$(MAKE) sv-inventory MODE=migration SOURCE=$(SOURCE) TARGET=$(TARGET); \
		echo ""; \
		echo "⏳ Starting migration with real-time progress monitoring..."; \
		echo "📊 Progress will be displayed every 10 seconds during transfer"; \
		echo "🔐 All files will be encrypted automatically on target"; \
		echo ""; \
		start_time=$$(date +%s); \
		if ansible-playbook -i $(SERVERS_INV) \
			-e "migrate_source=$(SOURCE) migrate_target=$(TARGET)" \
			--limit $(TARGET) $(SERVERS_PLAY)/migrate.yml; then \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo ""; \
			echo "🎉 Migration completed successfully in $${duration} seconds!"; \
			echo "✅ All data transferred and encrypted"; \
			echo "🔍 Check migration logs for detailed verification results"; \
		else \
			echo ""; \
			echo "❌ Migration failed. Check logs for details."; \
			exit 1; \
		fi; \
	else \
		echo "🔧 Using default source→destination migration..."; \
		$(MAKE) sv-inventory MODE=migration; \
		echo ""; \
		echo "⏳ Starting migration with real-time progress monitoring..."; \
		start_time=$$(date +%s); \
		if ansible-playbook -i $(SERVERS_INV) --limit destination $(SERVERS_PLAY)/migrate.yml; then \
			end_time=$$(date +%s); \
			duration=$$((end_time - start_time)); \
			echo ""; \
			echo "🎉 Migration completed successfully in $${duration} seconds!"; \
		else \
			echo ""; \
			echo "❌ Migration failed. Check logs for details."; \
			exit 1; \
		fi; \
	fi

# System testing (migrated to system-test.yml)
sv-test:
	@echo "🧪 System testing has been migrated to Ansible playbook"
	@echo "Run: ansible-playbook -i $(SERVERS_INV) $(SERVERS_PLAY)/system-test.yml"

sv-transfer:
	@echo "Transfer complete system: export from source and import to destination..."
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/export.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit destination $(SERVERS_PLAY)/import.yml --ask-become-pass

sv-provision:
	@echo "Running provision playbooks..."
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/common.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/security.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/modsecurity-nginx.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/monitoring.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/minio.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/misskey.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/ai.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/searxng.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/matrix.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/jitsi.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/vikunja.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/cryptpad.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/outline.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/uptime.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/deeplx.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/mcaptcha.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/ctfd.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/impostor.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/minecraft.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/neo-quesdon.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/lemmy.yml --ask-become-pass
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/misskey-backup.yml --ask-become-pass

help:
	@echo "Available targets:"
	@echo ""
	@echo "Appliances:"
	@echo "  ap-inventory   - Create TrueNAS inventory"
	@echo "  ap-setup       - Run appliances setup"
	@echo "  ap-migrate     - Run appliances migration"
	@echo "  ap-e2e         - End-to-end deploy + migrate"
	@echo "  ap-syntax      - Syntax-check appliances playbooks"
	@echo ""
	@echo "Setup & Prerequisites:"
	@echo "  install-ansible - Install Ansible and ansible-lint via uv (Python tools)"
	@echo "                    Provides unified Python-based tool management"
	@echo "                    Includes: ansible, ansible-lint, git"
	@echo ""
	@echo "Servers (Ansible Wrappers):"
	@echo "  sv-install    - Complete system initialization (Ansible + packages)"
	@echo "  sv-inventory  - Create servers inventory (MODE=migration for migration)"
	@echo "  sv-clone      - [MIGRATED] Run: ansible-playbook -i inventory playbooks/clone-repos.yml"
	@echo "  sv-provision  - Provision the server using Ansible"
	@echo "  sv-migrate    - Migrate MinIO data with encryption and progress monitoring"
	@echo "  sv-test       - [MIGRATED] Run: ansible-playbook -i inventory playbooks/system-test.yml"
	@echo "  sv-transfer   - Transfer complete system using export/import playbooks"
	@echo ""
	@echo "Operations (New Ansible Playbooks):"
	@echo "  ansible-playbook -i inventory playbooks/operations.yml -e op=status    # Service status"
	@echo "  ansible-playbook -i inventory playbooks/operations.yml -e op=health    # Health check"
	@echo "  ansible-playbook -i inventory playbooks/operations.yml -e op=logs      # View logs"
	@echo "  ansible-playbook -i inventory playbooks/operations.yml -e op=restart   # Restart services"
	@echo ""
