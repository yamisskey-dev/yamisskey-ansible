.PHONY: help install inventory run check list logs backup deploy
 .PHONY: build publish sanity

# Configuration - Modern Collections Architecture
COLLECTIONS_DIR := ansible_collections/yamisskey
# Legacy collection paths (still used for roles)
SERVERS_DIR := $(COLLECTIONS_DIR)/servers
APPLIANCES_DIR := $(COLLECTIONS_DIR)/appliances
DEPLOY_SERVERS_DIR := deploy/servers
DEPLOY_SERVERS_INV := $(DEPLOY_SERVERS_DIR)/inventory
DEPLOY_SERVERS_PLAY := $(DEPLOY_SERVERS_DIR)/playbooks
DEPLOY_APPLIANCES_DIR := deploy/appliances
DEPLOY_APPLIANCES_INV := $(DEPLOY_APPLIANCES_DIR)/inventory
DEPLOY_APPLIANCES_PLAY := $(DEPLOY_APPLIANCES_DIR)/playbooks
LOG_DIR := logs
BACKUP_DIR := backups

# Collections build/publish settings
COLL_BASE=ansible_collections/yamisskey
COLLS=servers appliances
VERSION?=1.0.0

# Core variables
ANSIBLE_CMD := ansible-playbook
TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)
PATH_WITH_ANSIBLE := $$HOME/.local/bin:$$PATH
COLLECTIONS_PATH := .

# Default target (servers)
TARGET ?= servers

# Ensure directories exist
$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR))

# === Core Functions ===

# Main playbook execution - Deploy-first
run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]" && exit 1)
	@if [ "$(TARGET)" = "appliances" ]; then \
		INV=$(DEPLOY_APPLIANCES_INV); PLAY=$(DEPLOY_APPLIANCES_PLAY); COLLECTION="yamisskey.appliances"; CONFIG=$(DEPLOY_APPLIANCES_DIR)/ansible.cfg; \
	else \
		INV=$(DEPLOY_SERVERS_INV); PLAY=$(DEPLOY_SERVERS_PLAY); COLLECTION="yamisskey.servers"; CONFIG=$(DEPLOY_SERVERS_DIR)/ansible.cfg; \
	fi; \
	test -f "$$PLAY/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $$PLAY/" && exit 1); \
	echo "🚀 Running $$COLLECTION: $(PLAYBOOK)"; \
	export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$(COLLECTIONS_PATH)"; \
	if [ -n "$$CONFIG" ]; then export ANSIBLE_CONFIG="$$CONFIG"; fi; \
	$(ANSIBLE_CMD) -i $$INV $$PLAY/$(PLAYBOOK).yml \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \
		--ask-become-pass

# Dry-run check - Deploy-first
check:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@if [ "$(TARGET)" = "appliances" ]; then \
		INV=$(DEPLOY_APPLIANCES_INV); PLAY=$(DEPLOY_APPLIANCES_PLAY); COLLECTION="yamisskey.appliances"; CONFIG=$(DEPLOY_APPLIANCES_DIR)/ansible.cfg; \
	else \
		INV=$(DEPLOY_SERVERS_INV); PLAY=$(DEPLOY_SERVERS_PLAY); COLLECTION="yamisskey.servers"; CONFIG=$(DEPLOY_SERVERS_DIR)/ansible.cfg; \
	fi; \
	test -f "$$PLAY/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $$PLAY/" && exit 1); \
	echo "🔍 Checking $$COLLECTION: $(PLAYBOOK)"; \
	export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$(COLLECTIONS_PATH)"; \
	if [ -n "$$CONFIG" ]; then export ANSIBLE_CONFIG="$$CONFIG"; fi; \
	$(ANSIBLE_CMD) -i $$INV $$PLAY/$(PLAYBOOK).yml \
		$(if $(LIMIT),--limit $(LIMIT)) \
		--check --diff

# Deploy multiple playbooks
deploy:
	@test -n "$(PLAYBOOKS)" || (echo "❌ Usage: make deploy PLAYBOOKS='<p1> <p2>' [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@echo "🚀 Deploying $(TARGET): $(PLAYBOOKS)"
	@for pb in $(PLAYBOOKS); do \
		$(MAKE) run PLAYBOOK=$$pb TARGET=$(TARGET) LIMIT=$(LIMIT) TAGS=$(TAGS) || exit 1; \
	done

# === Setup & Discovery ===

# Install Ansible and Collections
install:
	@echo "📦 Installing Ansible via uv..."
	@command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	uv tool install ansible; \
	uv tool install ansible-lint
	@echo "📦 Installing Collections..."
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	ansible-galaxy collection install -r requirements.yml
	@echo "✅ Ansible and Collections installed"
	@echo "🔍 Verifying Collections:"
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	ansible-galaxy collection list | grep yamisskey || echo "⚠️  yamisskey Collections not found"

# Create basic inventory
inventory:
	@echo "📋 Creating $(TARGET) inventory..."
	@if [ "$(TARGET)" = "appliances" ]; then \
		INV=$(DEPLOY_APPLIANCES_INV); \
		echo "[truenas]" > $$INV; \
		echo "truenas.local" >> $$INV; \
		echo "✅ Appliances inventory created at $$INV"; \
	else \
		INV=$(DEPLOY_SERVERS_INV); \
		CURRENT_HOST=$$(hostname); \
		echo "[local]" > $$INV; \
		echo "$$CURRENT_HOST ansible_connection=local" >> $$INV; \
		echo "" >> $$INV; \
		echo "[all:vars]" >> $$INV; \
		echo "ansible_python_interpreter=/usr/bin/python3" >> $$INV; \
		echo "ansible_become=true" >> $$INV; \
		echo "ansible_become_method=sudo" >> $$INV; \
		echo "ansible_become_user=root" >> $$INV; \
		echo "✅ Servers inventory created at $$INV"; \
	fi
	@echo "💡 Edit inventory file to add remote hosts as needed"

# List available playbooks
list:
	@echo "📋 Available $(TARGET) playbooks:"
	@if [ "$(TARGET)" = "appliances" ]; then \
		PLAY=$(DEPLOY_APPLIANCES_PLAY); \
	else \
		PLAY=$(DEPLOY_SERVERS_PLAY); \
	fi; \
	ls $$PLAY/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$$||' | sort | sed 's/^/  /'

# === Operations ===

# Show recent logs
logs:
	@echo "📋 Recent logs:"
	@find $(LOG_DIR) -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "  No recent logs"

# Backup inventory
backup:
	@echo "💾 Backing up $(TARGET) inventory..."
	@if [ "$(TARGET)" = "appliances" ]; then \
		INV=$(DEPLOY_APPLIANCES_INV); \
	else \
		INV=$(DEPLOY_SERVERS_INV); \
	fi; \
	test -f "$$INV" && cp "$$INV" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak" || true
	@echo "✅ Backup created"

# === Help ===
help:
	@echo "🚀 Unified Ansible Wrapper"
	@echo "=========================="
	@echo ""
	@echo "📋 Quick Start:"
	@echo "  make install                    # Install Ansible"
	@echo "  make inventory [TARGET=servers] # Create inventory"
	@echo "  make run PLAYBOOK=common        # Run playbook"
	@echo ""
	@echo "🔧 Core Commands:"
	@echo "  run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]"
	@echo "  check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]  # dry-run"
	@echo "  deploy PLAYBOOKS='<p1> <p2>' [TARGET=servers|appliances] [LIMIT=<hosts>]"
	@echo "  list [TARGET=servers|appliances]                                   # show playbooks"
	@echo ""
	@echo "🎯 Targets (Collections):"
	@echo "  TARGET=servers     (default) - Use yamisskey.servers Collection"
	@echo "  TARGET=appliances            - Use yamisskey.appliances Collection (TrueNAS)"
	@echo ""
	@echo "📊 Operations:"
	@echo "  inventory [TARGET=servers|appliances]  # create inventory"
	@echo "  backup [TARGET=servers|appliances]     # backup inventory"
	@echo "  logs                                    # recent logs"
	@echo ""
	@echo "💡 Examples (Collections):"
	@echo "  make install                                      # Install Ansible + Collections"
	@echo "  make run PLAYBOOK=common                          # yamisskey.servers"
	@echo "  make run PLAYBOOK=setup TARGET=appliances        # yamisskey.appliances"
	@echo "  make check PLAYBOOK=security LIMIT=local         # dry-run with Collections"
	@echo "  make deploy PLAYBOOKS='common security'          # sequence deployment"
	@echo "  make list TARGET=appliances                       # list appliances playbooks"

# === Collections Release Helpers ===

build:
	@for c in $(COLLS); do \
		( cd $(COLL_BASE)/$$c && \
		  ansible-galaxy collection build --force && \
		  mkdir -p ../../../dist/$$c && \
		  mv yamisskey-$$c-*.tar.gz ../../../dist/$$c/ \
		); \
	done

publish:
	@test -n "$$GALAXY_API_KEY" || (echo "GALAXY_API_KEY が未設定"; exit 1)
	@for c in $(COLLS); do \
		f=$$(ls dist/$$c/yamisskey-$$c-*.tar.gz | tail -n1) ; \
		ansible-galaxy collection publish $$f --token $$GALAXY_API_KEY ; \
	done

sanity:
	@for c in $(COLLS); do \
		( cd $(COLL_BASE)/$$c && ansible-test sanity --python 3.11 ); \
	done
