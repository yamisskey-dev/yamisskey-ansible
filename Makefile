.PHONY: help install inventory run check list logs backup deploy test
.PHONY: build publish sanity

## Configuration - Modern Collections Architecture
# Namespace + collections root
COLLECTION_NS := yamisskey
COLLECTIONS_DIR := ansible_collections/$(COLLECTION_NS)

# Targets and deploy directories
TARGET ?= servers
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

# ---------------- uv / paths ----------------
UV_BIN ?= $(HOME)/.local/bin
UV_PY ?= 3.11                        # ← Molecule/Ansible の安定版に固定
export PATH := $(UV_BIN):$(PATH)

# Galaxy collections local cache (conflict-free)
REPO_ROOT := $(abspath .)
GALAXY_DIR := $(REPO_ROOT)/.galaxy/collections

# Ansible lookup path順序: 1) Galaxyローカル 2) リポジトリ直下 3) ユーザ既定
ANSIBLE_PATHS := $(GALAXY_DIR):$(REPO_ROOT):$(HOME)/.ansible/collections

ANSIBLE_CMD := ansible-playbook
TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)
COLLECTIONS_PATH := $(REPO_ROOT)
CONFIG_ABS := $(abspath $(CONFIG))

# Unified Molecule launcher via uvx (pin Python; include docker plugin)
MOLECULE := uvx --python $(UV_PY) --from molecule --with "molecule-plugins[docker]" molecule

# Ensure directories exist
$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR) $(GALAXY_DIR))

# === Core Functions ===

run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🚀 Running $(COLLECTION): $(PLAYBOOK)"
	@export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
	$(ANSIBLE_CMD) -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \
		--ask-become-pass

check:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🔍 Checking $(COLLECTION): $(PLAYBOOK)"
	@export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
	$(ANSIBLE_CMD) -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		--check --diff

deploy:
	@test -n "$(PLAYBOOKS)" || (echo "❌ Usage: make deploy PLAYBOOKS='<p1> <p2>' [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@echo "🚀 Deploying $(TARGET): $(PLAYBOOKS)"
	@for pb in $(PLAYBOOKS); do \
		$(MAKE) run PLAYBOOK=$$pb TARGET=$(TARGET) LIMIT=$(LIMIT) TAGS=$(TAGS) || exit 1; \
	done

# === Setup & Discovery ===

install:
	@echo "📦 Installing Ansible toolchain via uv..."
	@command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
	@export PATH="$(UV_BIN):$$PATH"; \
	uv tool install --python $(UV_PY) ansible; \
	uv tool install --python $(UV_PY) ansible-lint
	@echo "📦 Installing Galaxy collections to $(GALAXY_DIR) ..."
	@ANSIBLE_GALAXY_CACHE_DIR="$(REPO_ROOT)/.galaxy/.cache" ansible-galaxy collection install -p "$(GALAXY_DIR)" -r requirements-dev.yml
	@echo "✅ Ansible and Collections installed via uv"
	@echo "🔍 Verifying installation:"
	@ansible --version | head -n1 || true
	@ansible-lint --version || true
	@ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)" ansible-galaxy collection list | grep yamisskey && echo "✅ local yamisskey visible" || echo "ℹ️ yamisskey will be loaded from repo path"
	@echo "🧪 Molecule runtime (uvx) check:"
	@$(MOLECULE) --version && echo "✅ Molecule available via uvx" || echo "⚠️ Molecule check failed (ensure Docker is available)"

inventory:
	@if [ "$(TYPE)" = "local" ]; then \
		echo "📋 Creating self-provisioning inventory for current host..."; \
		INV_PATH="$(INV)"; \
		TEMPLATE_PATH="$(DEPLOY_DIR)/inventory.example.local"; \
		if [ ! -f "$$TEMPLATE_PATH" ]; then \
			echo "❌ Local template not found: $$TEMPLATE_PATH"; \
			exit 1; \
		fi; \
		if [ -f "$$INV_PATH" ]; then \
			echo "⚠️  Inventory already exists. Creating backup..."; \
			cp "$$INV_PATH" "$(BACKUP_DIR)/$(TARGET)-inventory-local-$(TIMESTAMP).bak"; \
		fi; \
		CURRENT_HOST=$$(hostname); \
		CURRENT_USER=$$(whoami); \
		HOST_IP=$$(ip route get 1.1.1.1 | awk '{print $$7; exit}' 2>/dev/null || hostname -i 2>/dev/null | awk '{print $$1}' || echo "127.0.0.1"); \
		DOMAIN="$${DOMAIN:-yami.ski}"; \
		NETWORK="$${INTERNAL_NETWORK:-192.168.0.0/24}"; \
		HOST_ROLE="$${HOST_ROLE:-monitoring}"; \
		echo "🖥️  Detected system information:"; \
		echo "   - Hostname: $$CURRENT_HOST"; \
		echo "   - User: $$CURRENT_USER"; \
		echo "   - IP: $$HOST_IP"; \
		echo "   - Role: $$HOST_ROLE"; \
		echo "   - Domain: $$DOMAIN"; \
		echo "📄 Processing local template..."; \
		cp "$$TEMPLATE_PATH" "$$INV_PATH"; \
		sed -i.bak \
			-e "s|HOSTNAME_PLACEHOLDER|$$CURRENT_HOST|g" \
			-e "s|USER_PLACEHOLDER|$$CURRENT_USER|g" \
			-e "s|HOST_IP_PLACEHOLDER|$$HOST_IP|g" \
			-e "s|DOMAIN_PLACEHOLDER|$$DOMAIN|g" \
			-e "s|NETWORK_PLACEHOLDER|$$NETWORK|g" \
			-e "s|HOST_ROLE_PLACEHOLDER|$$HOST_ROLE|g" \
			-e "s|TIMESTAMP_PLACEHOLDER|$$(date)|g" \
			-e "s|GENERATED_DATE_PLACEHOLDER|$$(date -Iseconds)|g" \
			"$$INV_PATH"; \
		rm "$$INV_PATH.bak" 2>/dev/null || true; \
		echo "✅ Local inventory created at $$INV_PATH"; \
		echo ""; \
		echo "🚀 Usage examples:"; \
		echo "   make run PLAYBOOK=common LIMIT=localhost"; \
		echo "   make check PLAYBOOK=security LIMIT=localhost"; \
		echo ""; \
		echo "💡 Customize with environment variables:"; \
		echo "   DOMAIN=example.com HOST_ROLE=monitoring make inventory TYPE=local"; \
		echo "   INTERNAL_NETWORK=10.0.0.0/8 make inventory TYPE=local"; \
	else \
		echo "📋 Creating $(TARGET) inventory from template..."; \
		INV_PATH="$(INV)"; \
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
			echo "   - Linode  IP: $$LINODE_IP (tailscale)"; \
			echo "   - Raspberry IP: $$RASPBERRY_IP (tailscale)"; \
		else \
			echo "   - Joseph IP: $$JOSEPH_IP (tailscale)"; \
		fi; \
		echo ""; \
		echo "💡 Next Steps:"; \
		echo "   - Create and encrypt group_vars/vault.yml with vault_* variables"; \
		echo "   - Run: ansible-vault encrypt $(DEPLOY_DIR)/group_vars/vault.yml"; \
		echo "   - For self-provisioning: make inventory TYPE=local"; \
	fi

list:
	@echo "📋 Available $(TARGET) playbooks:"
	@ls "$(PLAY)"/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$$||' | sort | sed 's/^/  /'

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

logs:
	@echo "📋 Recent logs:"
	@find $(LOG_DIR) -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "  No recent logs"

backup:
	@echo "💾 Backing up $(TARGET) inventory..."
	@test -f "$(INV)" && cp "$(INV)" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak" || true
	@echo "✅ Backup created"

# === Testing (Molecule via uvx; docker required) ===
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
	if ! command -v docker >/dev/null 2>&1; then echo "❌ Docker not found. Install & start docker."; exit 1; fi; \
	if ! docker info >/dev/null 2>&1; then echo "❌ Docker daemon is not running."; exit 1; fi; \
	export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG)" ]; then export ANSIBLE_CONFIG="$(CONFIG)"; fi; \
	if [ -n "$(ROLE)" ]; then \
		ROLE_EFF="$(ROLE)"; \
		[ "$$ROLE_EFF" = "modsecurity" ] && ROLE_EFF="modsecurity-nginx"; \
		ROLE_DIR="$$ROLES_DIR/$$ROLE_EFF"; \
		if [ ! -d "$$ROLE_DIR" ]; then echo "❌ Role not found: $(ROLE) in $$ROLES_DIR"; exit 1; fi; \
		if [ ! -f "$$ROLE_DIR/molecule/default/molecule.yml" ]; then echo "❌ Molecule scenario missing for role: $(ROLE)"; exit 1; fi; \
		echo "🧪 $(COLLECTION) • $(ROLE) • molecule $$SUBCMD (uvx runtime py$(UV_PY))"; \
		(cd "$$ROLE_DIR" && $(MOLECULE) $$SUBCMD); \
		if [ -n "$$EXTRA" ]; then (cd "$$ROLE_DIR" && $(MOLECULE) $$EXTRA); fi; \
	else \
		ROLES=$$(find "$$ROLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -f {}/molecule/default/molecule.yml \; -print 2>/dev/null | sort); \
		if [ -z "$$ROLES" ]; then echo "⚠️  No roles with Molecule found under $$ROLES_DIR"; exit 0; fi; \
		COUNT=$$(echo "$$ROLES" | wc -w | tr -d ' '); \
		echo "🧪 $(COLLECTION) • $$COUNT roles • molecule $$SUBCMD (uvx runtime py$(UV_PY))"; \
		for r in $$ROLES; do \
			role_name=$$(basename "$$r"); \
			echo "📋 Testing $$role_name..."; \
			(cd "$$r" && $(MOLECULE) $$SUBCMD); \
			if [ -n "$$EXTRA" ]; then (cd "$$r" && $(MOLECULE) $$EXTRA); fi; \
		done; \
	fi

# === Help ===
help:
	@echo "🚀 Unified Ansible Wrapper (uv-only, py$(UV_PY))"
	@echo "==============================================="
	@echo ""
	@echo "📋 Quick Start:"
	@echo "  make install                    # Install Ansible (uv) + Galaxy collections (local cache)"
	@echo "  make inventory [TARGET=servers] # Create inventory"
	@echo "  make run PLAYBOOK=common        # Run playbook"
	@echo ""
	@echo "🔧 Core Commands:"
	@echo "  run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]"
	@echo "  check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]  # dry-run"
	@echo "  deploy PLAYBOOKS='<p1> <p2>' [TARGET=servers|appliances] [LIMIT=<hosts>]"
	@echo "  list [TARGET=servers|appliances]                                   # show playbooks"
	@echo ""
	@echo "🧪 Testing (uvx runtime – no global install):"
	@echo "  test                                    # run Molecule for all roles (auto-discover)"
	@echo "  test ROLE=<name>                        # run Molecule for a specific role"
	@echo "  test MODE=syntax|converge|cleanup       # pick a subcommand"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make install"
	@echo "  UV_PY=3.12 make install                 # (opt) pin a different Python for uv tools"
	@echo "  make test ROLE=minio MODE=syntax"

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
