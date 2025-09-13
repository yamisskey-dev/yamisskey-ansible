.PHONY: help install inventory run check list logs backup deploy test
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
PATH_WITH_ANSIBLE := $$HOME/.local/share/pipx/venvs/molecule/bin:$$HOME/.local/bin:$$PATH
# Resolve repository root once to an absolute path
REPO_ROOT := $(abspath .)
COLLECTIONS_PATH := $(REPO_ROOT)
# Absolute path for ansible.cfg (if present)
CONFIG_ABS := $(abspath $(CONFIG))

# Ensure directories exist
$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR))

# === Core Functions ===

# Main playbook execution - Deploy-first
run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🚀 Running $(COLLECTION): $(PLAYBOOK)"
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$$HOME/.ansible/collections:$(COLLECTIONS_PATH)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
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
	export ANSIBLE_COLLECTIONS_PATH="$$HOME/.ansible/collections:$(COLLECTIONS_PATH)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
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
	@echo "📦 Installing Molecule with pipx..."
	@command -v pipx >/dev/null || (echo "Installing pipx..." && python3 -m pip install --user pipx)
	@export PATH="$(PATH_WITH_ANSIBLE):$$HOME/.local/bin"; \
	pipx install molecule; \
	pipx inject molecule molecule-plugins[docker]
	@echo "📦 Installing Collections..."
	@export PATH="$(PATH_WITH_ANSIBLE)"; \
	ansible-galaxy collection install -r requirements.yml; \
	$$HOME/.local/share/pipx/venvs/molecule/bin/ansible-galaxy collection install community.docker --force
	@echo "✅ Ansible, Molecule and Collections installed"
	@echo "🔍 Verifying installation:"
	@export PATH="$(PATH_WITH_ANSIBLE):$$HOME/.local/bin"; \
	ansible-galaxy collection list | grep yamisskey || echo "⚠️  yamisskey Collections not found"; \
	molecule --version && echo "✅ Molecule installed" || echo "⚠️  Molecule installation failed"

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
	echo "📄 Processing template with Tailscale IPs..."; \
	cp "$$TEMPLATE_PATH" "$$INV_PATH"; \
	CURRENT_HOST=$$(hostname); \
	CURRENT_USER=$$(whoami); \
	DOMAIN="yami.ski"; \
	NETWORK="100.64.0.0/10"; \
	BALTHASAR_IP=$$(tailscale ip -4 balthasar 2>/dev/null); \
	CASPAR_IP=$$(tailscale ip -4 caspar 2>/dev/null); \
	LINODE_IP=$$(tailscale ip -4 linode-prox 2>/dev/null); \
	JOSEPH_IP=$$(tailscale ip -4 joseph 2>/dev/null); \
	RASPBERRY_IP=$$(tailscale ip -4 raspberrypi 2>/dev/null); \
	if [ -z "$$BALTHASAR_IP" ] || [ -z "$$CASPAR_IP" ] || [ -z "$$LINODE_IP" ]; then \
		echo "❌ Failed to resolve required Tailscale IPs. Check 'tailscale status'"; \
		exit 1; \
	fi; \
	if [ "$(TARGET)" = "servers" ] && [ -z "$$RASPBERRY_IP" ]; then \
		echo "❌ raspberrypi not found in Tailscale"; \
		exit 1; \
	fi; \
	if [ "$(TARGET)" = "appliances" ] && [ -z "$$JOSEPH_IP" ]; then \
		echo "❌ joseph not found in Tailscale"; \
		exit 1; \
	fi; \
	sed -i.bak \
		-e "s|HOSTNAME_PLACEHOLDER|$$CURRENT_HOST|g" \
		-e "s|DOMAIN_PLACEHOLDER|$$DOMAIN|g" \
		-e "s|USER_PLACEHOLDER|$$CURRENT_USER|g" \
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
	echo "🔧 Customization completed:"; \
	echo "   - Domain: $$DOMAIN"; \
	echo "   - User: $$CURRENT_USER (auto-detected)"; \
	echo "   - Network: $$NETWORK"; \
	if [ "$(TARGET)" = "servers" ]; then \
		echo "   - Balthasar IP: $$BALTHASAR_IP (tailscale)"; \
		echo "   - Caspar IP: $$CASPAR_IP (tailscale)"; \
		echo "   - Linode IP: $$LINODE_IP (tailscale)"; \
		echo "   - Raspberry IP: $$RASPBERRY_IP (tailscale)"; \
	else \
		echo "   - Joseph IP: $$JOSEPH_IP (tailscale)"; \
	fi; \
	echo ""; \
	echo "💡 Next Steps:"; \
	echo "   - Create and encrypt group_vars/vault.yml with vault_* variables"; \
	echo "   - Run: ansible-vault encrypt $(DEPLOY_DIR)/group_vars/vault.yml"

# List available playbooks
list:
	@echo "📋 Available $(TARGET) playbooks:"
	@ls "$(PLAY)"/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$$||' | sort | sed 's/^/  /'

# === Operations ===

# Comprehensive system status check
status:
	@echo "🔍 Infrastructure Status Check"
	@echo "========================================"
	@echo ""
	@echo "🌐 Network & DNS:"
	@ping -c 1 -W 3 yami.ski >/dev/null 2>&1 && echo "   ✅ yami.ski reachable" || echo "   ❌ yami.ski unreachable"
	@ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && echo "   ✅ Internet connectivity" || echo "   ❌ Internet connectivity failed"
	@nslookup yami.ski >/dev/null 2>&1 && echo "   ✅ DNS resolution working" || echo "   ❌ DNS resolution failed"
	@echo ""
	@echo "🚀 Tailscale Status:"
	@if command -v tailscale >/dev/null 2>&1; then \
		if tailscale status >/dev/null 2>&1; then \
			echo "   ✅ Tailscale connected"; \
			BALTHASAR_IP=$$(tailscale ip -4 balthasar 2>/dev/null); \
			CASPAR_IP=$$(tailscale ip -4 caspar 2>/dev/null); \
			JOSEPH_IP=$$(tailscale ip -4 joseph 2>/dev/null); \
			[ -n "$$BALTHASAR_IP" ] && echo "   ✅ balthasar: $$BALTHASAR_IP" || echo "   ❌ balthasar: offline"; \
			[ -n "$$CASPAR_IP" ] && echo "   ✅ caspar: $$CASPAR_IP" || echo "   ❌ caspar: offline"; \
			[ -n "$$JOSEPH_IP" ] && echo "   ✅ joseph: $$JOSEPH_IP" || echo "   ❌ joseph: offline"; \
		else \
			echo "   ❌ Tailscale disconnected"; \
		fi \
	else \
		echo "   ⚠️  Tailscale not installed"; \
	fi
	@echo ""
	@echo "🗄️  Storage Services:"
	@if command -v curl >/dev/null 2>&1; then \
		echo -n "   MinIO (drive): "; \
		STATUS_CODE=$$(curl -s -w "%{http_code}" -o /dev/null --max-time 10 https://drive.yami.ski/minio/health/live 2>/dev/null); \
		if [ "$$STATUS_CODE" = "200" ]; then \
			echo "✅ OK"; \
		elif [ "$$STATUS_CODE" = "403" ]; then \
			echo "✅ OK (403 expected)"; \
		elif [ "$$STATUS_CODE" = "000" ]; then \
			echo "❌ NO RESPONSE"; \
		else \
			echo "⚠️  HTTP $$STATUS_CODE"; \
		fi; \
	fi
	@echo ""
	@echo "📊 Monitoring Services:"
	@if command -v curl >/dev/null 2>&1; then \
		echo -n "   Grafana: "; \
		STATUS_CODE=$$(curl -s -w "%{http_code}" -o /dev/null --max-time 5 https://grafana.yami.ski/api/health 2>/dev/null); \
		if [ "$$STATUS_CODE" = "200" ]; then \
			echo "✅ OK"; \
		elif [ "$$STATUS_CODE" = "000" ]; then \
			echo "❌ NO RESPONSE"; \
		else \
			echo "⚠️  HTTP $$STATUS_CODE"; \
		fi; \
	fi

# Show recent logs
logs:
	@echo "📋 Recent logs:"
	@find $(LOG_DIR) -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "  No recent logs"

# Backup inventory
backup:
	@echo "💾 Backing up $(TARGET) inventory..."
	@test -f "$(INV)" && cp "$(INV)" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak" || true
	@echo "✅ Backup created"

# === Testing ===

# Unified Molecule wrapper with same abstraction as other targets
# Variables:
#   ROLE=<role-name>     # e.g., modsecurity-nginx, minio, misskey
#   MODE=<mode>          # one of: test (default), syntax, converge, cleanup
#   TARGET=<collection>  # servers (default) or appliances
test:
	@ROLES_DIR="$(COLLECTIONS_DIR)/$(TARGET)/roles"; \
	MODE_EFF="$(MODE)"; [ -n "$$MODE_EFF" ] || MODE_EFF=test; \
	SUBCMD="test"; EXTRA=""; \
	case "$$MODE_EFF" in \
	  syntax)   SUBCMD="syntax";; \
	  converge) SUBCMD="converge";; \
	  cleanup)  SUBCMD="cleanup"; EXTRA="destroy || true";; \
	  test)     SUBCMD="test";; \
	  *) echo "❌ Invalid MODE. Use: syntax, converge, cleanup, or test"; exit 1;; \
	esac; \
	export PATH="$(PATH_WITH_ANSIBLE)"; \
	export ANSIBLE_COLLECTIONS_PATH="$$HOME/.ansible/collections:$(COLLECTIONS_PATH)"; \
	if [ -f "$(CONFIG)" ]; then export ANSIBLE_CONFIG="$(CONFIG)"; fi; \
	if [ -n "$(ROLE)" ]; then \
		ROLE_EFF="$(ROLE)"; \
		[ "$$ROLE_EFF" = "modsecurity" ] && ROLE_EFF="modsecurity-nginx"; \
		ROLE_DIR="$$ROLES_DIR/$$ROLE_EFF"; \
		if [ ! -d "$$ROLE_DIR" ]; then echo "❌ Role not found: $(ROLE) in $$ROLES_DIR"; exit 1; fi; \
		if [ ! -f "$$ROLE_DIR/molecule/default/molecule.yml" ]; then echo "❌ Molecule scenario missing for role: $(ROLE)"; exit 1; fi; \
		echo "🧪 $(COLLECTION) • $(ROLE) • molecule $$SUBCMD"; \
		(cd "$$ROLE_DIR" && molecule $$SUBCMD); \
		if [ -n "$$EXTRA" ]; then (cd "$$ROLE_DIR" && molecule $$EXTRA); fi; \
	else \
		ROLES=$$(find "$$ROLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -f {}/molecule/default/molecule.yml \; -print 2>/dev/null | sort); \
		if [ -z "$$ROLES" ]; then echo "⚠️  No roles with Molecule found under $$ROLES_DIR"; exit 0; fi; \
		COUNT=$$(echo "$$ROLES" | wc -w | tr -d ' '); \
		echo "🧪 $(COLLECTION) • $$COUNT roles • molecule $$SUBCMD"; \
		for r in $$ROLES; do \
			role_name=$$(basename "$$r"); \
			echo "📋 Testing $$role_name..."; \
			(cd "$$r" && molecule $$SUBCMD); \
			if [ -n "$$EXTRA" ]; then (cd "$$r" && molecule $$EXTRA); fi; \
		done; \
	fi

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
	@echo "  status                                  # comprehensive infrastructure status"
	@echo "  inventory [TARGET=servers|appliances]  # create inventory"
	@echo "  backup [TARGET=servers|appliances]     # backup inventory"
	@echo "  logs                                    # recent logs"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test                                    # run Molecule for all roles (auto-discover)"
	@echo "  test ROLE=<name>                        # run Molecule for a specific role"
	@echo "  test MODE=syntax                        # quick syntax checks"
	@echo "  test MODE=converge                      # run converge only"
	@echo "  test MODE=cleanup                       # cleanup + destroy environments"
	@echo "  test ROLE=minio MODE=syntax             # syntax check for specific role"
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
