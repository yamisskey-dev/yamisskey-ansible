.PHONY: help install inventory run check list logs backup deploy
 .PHONY: build publish sanity

## Configuration - Modern Collections Architecture
# Namespace + collections root
COLLECTION_NS := yamisskey
COLLECTIONS_DIR := ansible_collections/$(COLLECTION_NS)

# Targets and deploy directories
TARGET ?= servers
# normalize TARGET to avoid trailing spaces breaking indirection
TARGET := $(strip $(TARGET))
DEPLOY_DIR_servers := deploy/servers
DEPLOY_DIR_appliances := deploy/appliances

# Derived paths (based on TARGET)
DEPLOY_DIR := $(DEPLOY_DIR_$(TARGET))
INV := $(DEPLOY_DIR)/inventory
PLAY := $(DEPLOY_DIR)/playbooks
CONFIG := $(DEPLOY_DIR)/ansible.cfg

# Collection names (based on TARGET)
COLLECTION_NAME_servers := $(COLLECTION_NS).servers
COLLECTION_NAME_appliances := $(COLLECTION_NS).appliances
COLLECTION := $(COLLECTION_NAME_$(TARGET))

# Logs/backups
LOG_DIR := logs
BACKUP_DIR := backups

# Collections build/publish settings
COLL_BASE := $(COLLECTIONS_DIR)
COLLS := servers appliances
VERSION ?= 1.0.0

# Core variables
ANSIBLE_CMD := ansible-playbook
TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)
PATH_WITH_ANSIBLE := $$HOME/.local/bin:$$PATH
COLLECTIONS_PATH := .

# Ensure directories exist
$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR))

# === Core Functions ===

# Main playbook execution - Deploy-first
run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🚀 Running $(COLLECTION): $(PLAYBOOK)"
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$(COLLECTIONS_PATH)"; \
	if [ -f "$(CONFIG)" ]; then export ANSIBLE_CONFIG="$(CONFIG)"; fi; \
	$(ANSIBLE_CMD) -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \
		--ask-become-pass

# Dry-run check - Deploy-first
check:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🔍 Checking $(COLLECTION): $(PLAYBOOK)"
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$(COLLECTIONS_PATH)"; \
	if [ -f "$(CONFIG)" ]; then export ANSIBLE_CONFIG="$(CONFIG)"; fi; \
	$(ANSIBLE_CMD) -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
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

# Create inventory from template with environment variable substitution
inventory:
	@echo "📋 Creating $(TARGET) inventory from template..."
	@INV_PATH="$(INV)"; \
	TEMPLATE_PATH="$(DEPLOY_DIR)/inventory.example"; \
	if [ ! -f "$$TEMPLATE_PATH" ]; then \
		echo "❌ Template not found: $$TEMPLATE_PATH"; \
		exit 1; \
	fi; \
	if [ -f "$$INV_PATH" ]; then \
		echo "⚠️  Inventory already exists. Creating backup..."; \
		cp "$$INV_PATH" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak"; \
	fi; \
	echo "📄 Processing template with environment variables..."; \
	cp "$$TEMPLATE_PATH" "$$INV_PATH"; \
	CURRENT_HOST=$$(hostname); \
	DOMAIN="$${YAMISSKEY_DOMAIN:-yami.ski}"; \
	USER="$${YAMISSKEY_USER:-taka}"; \
	BALTHASAR_IP="$${BALTHASAR_IP:-10.0.1.10}"; \
	CASPAR_IP="$${CASPAR_IP:-10.0.1.20}"; \
	LINODE_IP="$${LINODE_IP:-45.79.XXX.XXX}"; \
	JOSEPH_IP="$${JOSEPH_IP:-10.0.1.50}"; \
	RASPBERRY_IP="$${RASPBERRY_IP:-10.0.1.60}"; \
	NETWORK="$${INTERNAL_NETWORK:-10.0.1.0/24}"; \
	sed -i.bak \
		-e "s|HOSTNAME_PLACEHOLDER|$$CURRENT_HOST|g" \
		-e "s|DOMAIN_PLACEHOLDER|$$DOMAIN|g" \
		-e "s|USER_PLACEHOLDER|$$USER|g" \
		-e "s|BALTHASAR_IP_PLACEHOLDER|$$BALTHASAR_IP|g" \
		-e "s|CASPAR_IP_PLACEHOLDER|$$CASPAR_IP|g" \
		-e "s|LINODE_IP_PLACEHOLDER|$$LINODE_IP|g" \
		-e "s|JOSEPH_IP_PLACEHOLDER|$$JOSEPH_IP|g" \
		-e "s|RASPBERRY_IP_PLACEHOLDER|$$RASPBERRY_IP|g" \
		-e "s|NETWORK_PLACEHOLDER|$$NETWORK|g" \
		"$$INV_PATH"; \
	rm "$$INV_PATH.bak" 2>/dev/null || true; \
	echo "✅ $(TARGET) inventory created from template at $$INV_PATH"; \
	echo ""; \
	echo "🔧 Customization completed with environment variables:"; \
	echo "   - Domain: $$DOMAIN (YAMISSKEY_DOMAIN)"; \
	echo "   - User: $$USER (YAMISSKEY_USER)"; \
	echo "   - Network: $$NETWORK (INTERNAL_NETWORK)"; \
	if [ "$(TARGET)" = "servers" ]; then \
		echo "   - Balthasar IP: $$BALTHASAR_IP (BALTHASAR_IP)"; \
		echo "   - Caspar IP: $$CASPAR_IP (CASPAR_IP)"; \
		echo "   - Linode IP: $$LINODE_IP (LINODE_IP)"; \
		echo "   - Raspberry IP: $$RASPBERRY_IP (RASPBERRY_IP)"; \
	else \
		echo "   - Joseph IP: $$JOSEPH_IP (JOSEPH_IP)"; \
	fi; \
	echo ""; \
	echo "💡 Environment Variables for Customization:"; \
	if [ "$(TARGET)" = "servers" ]; then \
		echo "   YAMISSKEY_DOMAIN=example.com BALTHASAR_IP=192.168.1.10 make inventory"; \
	else \
		echo "   YAMISSKEY_DOMAIN=example.com JOSEPH_IP=192.168.1.50 make inventory TARGET=appliances"; \
	fi; \
	echo ""; \
	echo "📋 Still Required (manual):"; \
	echo "   - Create and encrypt group_vars/vault.yml with vault_* variables"; \
	echo "   - Run: ansible-vault encrypt $(DEPLOY_DIR)/group_vars/vault.yml"

# List available playbooks
list:
	@echo "📋 Available $(TARGET) playbooks:"
	@ls "$(PLAY)"/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$$||' | sort | sed 's/^/  /'

# === Operations ===

# Show recent logs
logs:
	@echo "📋 Recent logs:"
	@find $(LOG_DIR) -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "  No recent logs"

# Backup inventory
backup:
	@echo "💾 Backing up $(TARGET) inventory..."
	@test -f "$(INV)" && cp "$(INV)" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak" || true
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
