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

# Common Ansible configuration
ANSIBLE_PATH := $$HOME/.local/bin:$$PATH
ANSIBLE_COMMON_OPTS := -i $(SERVERS_INV)
ANSIBLE_BECOME_OPTS := --ask-become-pass

# Logging configuration
LOG_DIR := logs
LOG_FILE := $(LOG_DIR)/ansible-$(shell date +%Y%m%d).log
BACKUP_DIR := backups
TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)

# Ensure log directory exists
$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR))

# Environment variables to Ansible variables conversion
ANSIBLE_EXTRA_VARS := $(if $(HOST_SERVICES),-e "host_services=$(HOST_SERVICES)") \
                     $(if $(BACKUP_RETENTION),-e "backup_retention=$(BACKUP_RETENTION)") \
                     $(if $(DEBUG_MODE),-e "debug_mode=$(DEBUG_MODE)") \
                     $(if $(FORCE_RECREATE),-e "force_recreate=$(FORCE_RECREATE)") \
                     $(if $(SKIP_TAGS),-e "skip_tags=$(SKIP_TAGS)") \
                     $(if $(ONLY_TAGS),-e "only_tags=$(ONLY_TAGS)")

# Common execution presets
PRESET_DEVELOPMENT := --tags "install,config" -e "debug_mode=true" -e "force_recreate=true"
PRESET_PRODUCTION := --tags "install,config,security" -e "debug_mode=false"
PRESET_MINIMAL := --tags "install" --skip-tags "optional"
PRESET_UPDATE := --tags "update,config" -e "force_recreate=false"

# Get preset configuration
define get_preset
$(if $(filter development,$(1)),$(PRESET_DEVELOPMENT),\
$(if $(filter production,$(1)),$(PRESET_PRODUCTION),\
$(if $(filter minimal,$(1)),$(PRESET_MINIMAL),\
$(if $(filter update,$(1)),$(PRESET_UPDATE),$(1)))))
endef

# Ansible wrapper functions
define ansible_run
	@echo "🚀 Running Ansible playbook: $(1)"
	@echo "📋 Logging to: $(LOG_FILE)"
	@if [ ! -f "$(SERVERS_PLAY)/$(1).yml" ]; then \
		echo "❌ Playbook $(1).yml not found in $(SERVERS_PLAY)/"; \
		echo "[$(TIMESTAMP)] ERROR: Playbook $(1).yml not found" >> $(LOG_FILE); \
		exit 1; \
	fi
	@echo "[$(TIMESTAMP)] START: $(1) $(if $(2),limit=$(2)) $(if $(3),preset/extra=$(3))" >> $(LOG_FILE)
	@export PATH="$(ANSIBLE_PATH)"; \
	if ansible-playbook $(ANSIBLE_COMMON_OPTS) $(SERVERS_PLAY)/$(1).yml $(if $(2),--limit $(2)) $(ANSIBLE_EXTRA_VARS) $(call get_preset,$(3)) $(ANSIBLE_BECOME_OPTS) 2>&1 | tee -a $(LOG_FILE); then \
		echo "[$(TIMESTAMP)] SUCCESS: $(1)" >> $(LOG_FILE); \
		echo "✅ Playbook $(1) completed successfully"; \
	else \
		echo "[$(TIMESTAMP)] FAILED: $(1)" >> $(LOG_FILE); \
		echo "❌ Playbook $(1) failed. Check logs: $(LOG_FILE)"; \
		echo "💡 Run 'make logs' to view recent logs"; \
		exit 1; \
	fi
endef

define ansible_run_no_become
	@echo "🚀 Running Ansible playbook: $(1)"
	@echo "📋 Logging to: $(LOG_FILE)"
	@if [ ! -f "$(SERVERS_PLAY)/$(1).yml" ]; then \
		echo "❌ Playbook $(1).yml not found in $(SERVERS_PLAY)/"; \
		echo "[$(TIMESTAMP)] ERROR: Playbook $(1).yml not found" >> $(LOG_FILE); \
		exit 1; \
	fi
	@echo "[$(TIMESTAMP)] START: $(1) $(if $(2),limit=$(2)) $(if $(3),preset/extra=$(3))" >> $(LOG_FILE)
	@export PATH="$(ANSIBLE_PATH)"; \
	if ansible-playbook $(ANSIBLE_COMMON_OPTS) $(SERVERS_PLAY)/$(1).yml $(if $(2),--limit $(2)) $(ANSIBLE_EXTRA_VARS) $(call get_preset,$(3)) 2>&1 | tee -a $(LOG_FILE); then \
		echo "[$(TIMESTAMP)] SUCCESS: $(1)" >> $(LOG_FILE); \
		echo "✅ Playbook $(1) completed successfully"; \
	else \
		echo "[$(TIMESTAMP)] FAILED: $(1)" >> $(LOG_FILE); \
		echo "❌ Playbook $(1) failed. Check logs: $(LOG_FILE)"; \
		echo "💡 Run 'make logs' to view recent logs"; \
		exit 1; \
	fi
endef

define ansible_check
	@echo "🔍 Checking Ansible playbook: $(1)"
	@if [ ! -f "$(SERVERS_PLAY)/$(1).yml" ]; then \
		echo "❌ Playbook $(1).yml not found in $(SERVERS_PLAY)/"; \
		exit 1; \
	fi
	@export PATH="$(ANSIBLE_PATH)"; \
	ansible-playbook $(ANSIBLE_COMMON_OPTS) $(SERVERS_PLAY)/$(1).yml $(if $(2),--limit $(2)) $(ANSIBLE_EXTRA_VARS) --check --diff $(call get_preset,$(3))
endef

define ansible_syntax
	@echo "📝 Syntax check for Ansible playbook: $(1)"
	@if [ ! -f "$(SERVERS_PLAY)/$(1).yml" ]; then \
		echo "❌ Playbook $(1).yml not found in $(SERVERS_PLAY)/"; \
		exit 1; \
	fi
	@export PATH="$(ANSIBLE_PATH)"; \
	ansible-playbook $(ANSIBLE_COMMON_OPTS) $(SERVERS_PLAY)/$(1).yml --syntax-check
endef

# Appliances inventory helper (minimal)
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

all: sv-inventory sv-provision

# Generic playbook execution
run:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "❌ PLAYBOOK parameter is required"; \
		echo "Usage: make run PLAYBOOK=<playbook-name> [LIMIT=<host-group>] [PRESET=<preset>] [EXTRA='<extra-args>']"; \
		echo "Examples:"; \
		echo "  make run PLAYBOOK=common"; \
		echo "  make run PLAYBOOK=security LIMIT=source"; \
		echo "  make run PLAYBOOK=monitoring PRESET=development"; \
		echo "  make run PLAYBOOK=misskey PRESET=production LIMIT=source"; \
		echo ""; \
		echo "Available presets: development, production, minimal, update"; \
		echo "Environment variables: HOST_SERVICES, DEBUG_MODE, FORCE_RECREATE, etc."; \
		exit 1; \
	fi
	$(call ansible_run,$(PLAYBOOK),$(LIMIT),$(if $(PRESET),$(PRESET),$(EXTRA)))

# Generic playbook check (dry-run)
check:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "❌ PLAYBOOK parameter is required"; \
		echo "Usage: make check PLAYBOOK=<playbook-name> [LIMIT=<host-group>] [PRESET=<preset>]"; \
		exit 1; \
	fi
	$(call ansible_check,$(PLAYBOOK),$(LIMIT),$(PRESET))

# Generic syntax check
syntax:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "❌ PLAYBOOK parameter is required"; \
		echo "Usage: make syntax PLAYBOOK=<playbook-name>"; \
		exit 1; \
	fi
	$(call ansible_syntax,$(PLAYBOOK))

# List available playbooks
list:
	@echo "📋 Available playbooks:"
	@if [ -d "$(SERVERS_PLAY)" ]; then \
		ls $(SERVERS_PLAY)/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$$||' | sort | sed 's/^/  - /'; \
	else \
		echo "  No playbooks found in $(SERVERS_PLAY)"; \
	fi
	@echo ""
	@echo "📦 Available presets:"
	@echo "  - development: install,config with debug mode"
	@echo "  - production:  install,config,security without debug"
	@echo "  - minimal:     install only, skip optional tasks"
	@echo "  - update:      update,config without recreate"
	@echo ""
	@echo "🔧 Environment variables:"
	@echo "  - HOST_SERVICES:    comma-separated list of services"
	@echo "  - DEBUG_MODE:       true/false for debug output"
	@echo "  - FORCE_RECREATE:   true/false to force recreation"
	@echo "  - BACKUP_RETENTION: number of backups to keep"

# Log management
logs:
	@echo "📋 Recent Ansible logs:"
	@if [ -f "$(LOG_FILE)" ]; then \
		tail -50 $(LOG_FILE); \
	else \
		echo "  No logs found for today. Check $(LOG_DIR)/ for other dates."; \
	fi

# View all log files
logs-all:
	@echo "📋 Available log files:"
	@ls -la $(LOG_DIR)/ 2>/dev/null || echo "  No log directory found"

# Clean old logs (keep last 7 days)
logs-clean:
	@echo "🧹 Cleaning old logs (keeping last 7 days)..."
	@find $(LOG_DIR) -name "ansible-*.log" -mtime +7 -delete 2>/dev/null || true
	@echo "✅ Log cleanup completed"

# Backup inventory before operations
backup:
	@echo "💾 Creating backup of inventory..."
	@if [ -f "$(SERVERS_INV)" ]; then \
		cp "$(SERVERS_INV)" "$(BACKUP_DIR)/inventory-$(TIMESTAMP).bak"; \
		echo "✅ Backup created: $(BACKUP_DIR)/inventory-$(TIMESTAMP).bak"; \
	else \
		echo "⚠️  No inventory file to backup"; \
	fi

# Restore from backup
restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "❌ BACKUP_FILE parameter is required"; \
		echo "Usage: make restore BACKUP_FILE=<backup-filename>"; \
		echo "Available backups:"; \
		ls -la $(BACKUP_DIR)/ 2>/dev/null | grep "inventory-" || echo "  No backups found"; \
		exit 1; \
	fi
	@if [ -f "$(BACKUP_DIR)/$(BACKUP_FILE)" ]; then \
		cp "$(BACKUP_DIR)/$(BACKUP_FILE)" "$(SERVERS_INV)"; \
		echo "✅ Restored from backup: $(BACKUP_FILE)"; \
	else \
		echo "❌ Backup file not found: $(BACKUP_DIR)/$(BACKUP_FILE)"; \
	fi

# Clean old backups (keep last 10)
backup-clean:
	@echo "🧹 Cleaning old backups (keeping last 10)..."
	@ls -t $(BACKUP_DIR)/inventory-*.bak 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
	@echo "✅ Backup cleanup completed"

# Run multiple playbooks in sequence
deploy:
	@if [ -z "$(PLAYBOOKS)" ]; then \
		echo "❌ PLAYBOOKS parameter is required"; \
		echo "Usage: make deploy PLAYBOOKS='<playbook1> <playbook2> ...' [LIMIT=<host-group>] [PRESET=<preset>]"; \
		echo "Example: make deploy PLAYBOOKS='common security monitoring' LIMIT=source PRESET=production"; \
		exit 1; \
	fi
	@echo "🚀 Running playbook sequence: $(PLAYBOOKS)"
	@for playbook in $(PLAYBOOKS); do \
		echo ""; \
		echo "▶️ Running: $$playbook"; \
		$(MAKE) run PLAYBOOK=$$playbook LIMIT=$(LIMIT) PRESET=$(PRESET) EXTRA=$(EXTRA) || exit 1; \
	done
	@echo ""
	@echo "🎉 All playbooks completed successfully!"

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

# Simple inventory creation
sv-inventory:
	@echo "📋 Creating servers inventory..."
	@CURRENT_HOST=$$(hostname); \
	echo "[local]" > $(SERVERS_INV); \
	echo "$$CURRENT_HOST ansible_connection=local" >> $(SERVERS_INV); \
	echo "" >> $(SERVERS_INV); \
	echo "[all:vars]" >> $(SERVERS_INV); \
	echo "ansible_python_interpreter=/usr/bin/python3" >> $(SERVERS_INV); \
	echo "ansible_become=true" >> $(SERVERS_INV); \
	echo "ansible_become_method=sudo" >> $(SERVERS_INV); \
	echo "ansible_become_user=root" >> $(SERVERS_INV); \
	echo "✅ Basic inventory created at $(SERVERS_INV)"
	@echo "💡 Edit manually for multi-host setups or use generic Ansible patterns"

help:
	@echo "🚀 Ansible Wrapper - Flexible Infrastructure Management"
	@echo "=================================================================="
	@echo ""
	@echo "📋 QUICK START:"
	@echo "  1. make install-ansible     # Install Ansible tools"
	@echo "  2. make sv-inventory         # Create basic inventory"
	@echo "  3. make run PLAYBOOK=common  # Run your first playbook"
	@echo ""
	@echo "🔧 CORE COMMANDS:"
	@echo "  run PLAYBOOK=<name>         - Run any playbook with advanced options"
	@echo "  check PLAYBOOK=<name>       - Dry-run (--check --diff)"
	@echo "  syntax PLAYBOOK=<name>      - Syntax check"
	@echo "  list                        - List available playbooks and presets"
	@echo "  deploy PLAYBOOKS='a b c'    - Run multiple playbooks in sequence"
	@echo ""
	@echo "📊 MONITORING & LOGS:"
	@echo "  logs                        - View recent execution logs"
	@echo "  logs-all                    - List all log files"
	@echo "  logs-clean                  - Clean old logs (keep 7 days)"
	@echo ""
	@echo "💾 BACKUP & RESTORE:"
	@echo "  backup                      - Backup current inventory"
	@echo "  restore BACKUP_FILE=<file>  - Restore from backup"
	@echo "  backup-clean                - Clean old backups (keep 10)"
	@echo ""
	@echo "⚙️ SETUP:"
	@echo "  install-ansible             - Install Ansible and tools via uv"
	@echo "  sv-inventory                - Create basic inventory file"
	@echo "  ap-inventory                - Create appliances inventory"
	@echo ""
	@echo "📚 USAGE EXAMPLES:"
	@echo "  make run PLAYBOOK=common                     # Basic execution"
	@echo "  make run PLAYBOOK=security LIMIT=local      # Target specific hosts"
	@echo "  make run PLAYBOOK=misskey PRESET=production # Use preset configuration"
	@echo "  make deploy PLAYBOOKS='common security monitoring'"
	@echo "  make check PLAYBOOK=nginx                    # Dry-run check"
	@echo ""
	@echo "🔍 MORE INFO:"
	@echo "  make list                   # Show all available options"
	@echo "  make help-advanced          # Advanced usage and environment variables"
	@echo ""

# Advanced help with detailed examples
help-advanced:
	@echo "🔧 ADVANCED USAGE"
	@echo "=================="
	@echo ""
	@echo "🎯 PRESETS (Use with PRESET=<name>):"
	@echo "  development - install,config + debug mode + force recreate"
	@echo "  production  - install,config,security - debug mode"
	@echo "  minimal     - install only, skip optional tasks"
	@echo "  update      - update,config without recreate"
	@echo ""
	@echo "🌍 ENVIRONMENT VARIABLES:"
	@echo "  HOST_SERVICES='svc1,svc2'   - Specify services to manage"
	@echo "  DEBUG_MODE=true              - Enable debug output"
	@echo "  FORCE_RECREATE=true          - Force recreation of resources"
	@echo "  BACKUP_RETENTION=30          - Number of backups to keep"
	@echo "  SKIP_TAGS='optional,docs'    - Skip specific tags"
	@echo "  ONLY_TAGS='install,config'   - Run only specific tags"
	@echo ""
	@echo "📋 COMPLEX EXAMPLES:"
	@echo "  # Production deployment with specific services"
	@echo "  HOST_SERVICES='nginx,redis' make run PLAYBOOK=web PRESET=production"
	@echo ""
	@echo "  # Development setup with debug"
	@echo "  DEBUG_MODE=true FORCE_RECREATE=true make run PLAYBOOK=dev"
	@echo ""
	@echo "  # Sequential deployment with error handling"
	@echo "  make deploy PLAYBOOKS='common security web' PRESET=production || make logs"
	@echo ""
	@echo "  # Custom configuration with tags"
	@echo "  make run PLAYBOOK=app EXTRA='--tags install,config --skip-tags optional'"
	@echo ""
	@echo "📁 FILE LOCATIONS:"
	@echo "  Playbooks: $(SERVERS_PLAY)/"
	@echo "  Inventory: $(SERVERS_INV)"
	@echo "  Logs:      $(LOG_DIR)/"
	@echo "  Backups:   $(BACKUP_DIR)/"
	@echo ""
	@echo "🔗 TIPS:"
	@echo "  - Always run 'make backup' before major changes"
	@echo "  - Use 'make check' to verify changes before applying"
	@echo "  - Check 'make logs' if operations fail"
	@echo "  - Use presets for consistent environments"
	@echo "  - Edit inventory manually for multi-host setups"
	@echo ""
