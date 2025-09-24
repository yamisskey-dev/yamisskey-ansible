.PHONY: help install inventory run check list logs backup deploy test
.PHONY: build publish sanity
.PHONY: sops-install sops-edit sops-view sops-status sops-updatekeys

## Configuration - Modern Collections Architecture
COLLECTION_NS := yamisskey
COLLECTIONS_DIR := ansible_collections/$(COLLECTION_NS)

TARGET ?= servers
TARGET := $(strip $(TARGET))
DEPLOY_DIR_servers := deploy/servers
DEPLOY_DIR_appliances := deploy/appliances

DEPLOY_DIR := $(DEPLOY_DIR_$(TARGET))
INV := $(DEPLOY_DIR)/inventory
PLAY := $(DEPLOY_DIR)/playbooks
CONFIG := $(DEPLOY_DIR)/ansible.cfg

COLLECTION_NAME_servers := $(COLLECTION_NS).servers
COLLECTION_NAME_appliances := $(COLLECTION_NS).appliances
COLLECTION := $(COLLECTION_NAME_$(TARGET))

LOG_DIR := logs
BACKUP_DIR := backups

COLL_BASE := $(COLLECTIONS_DIR)
COLLS := servers appliances
VERSION ?= 1.0.0

# Secret management
SOPS_BIN ?= $(shell command -v sops 2>/dev/null)
SOPS_BIN := $(if $(SOPS_BIN),$(SOPS_BIN),sops)
AGE_BIN ?= $(shell command -v age 2>/dev/null)
AGE_BIN := $(if $(AGE_BIN),$(AGE_BIN),age)
AGE_KEY_FILE ?= $(REPO_ROOT)/age-key.txt
SOPS_FILE_servers := $(DEPLOY_DIR_servers)/group_vars/vault.yml
SOPS_FILE_appliances := $(DEPLOY_DIR_appliances)/group_vars/vault.yml
SOPS_FILE := $(SOPS_FILE_$(TARGET))

# ---------------- uv / paths ----------------
UV_BIN ?= $(HOME)/.local/bin
UV_PY  ?= 3.11
export PATH := $(UV_BIN):$(PATH)

# ansible-core の解決ポリシー
# - 既定: 最新（バージョン指定なしで uvx 取得）
# - 固定したい場合: ANSIBLE_CORE_VERSION=2.19.* など環境変数で上書き
ifdef ANSIBLE_CORE_VERSION
ANSIBLE_CORE_SPEC := ansible-core==$(ANSIBLE_CORE_VERSION)
else
ANSIBLE_CORE_SPEC := ansible-core
endif

# 使い回し
REPO_ROOT := $(abspath .)
SHIM_DIR  := $(REPO_ROOT)/.bin
GALAXY_DIR := $(REPO_ROOT)/.vendor/collections
ANSIBLE_PATHS := $(GALAXY_DIR):$(REPO_ROOT):$(HOME)/.ansible/collections

ANSIBLE_CMD := ansible-playbook
TIMESTAMP := $(shell date +%Y%m%dT%H%M%S)
COLLECTIONS_PATH := $(REPO_ROOT)
CONFIG_ABS := $(abspath $(CONFIG))

# Molecule（テスト用は uvx ランタイムに任せる）
MOLECULE := uvx --python $(UV_PY) --from molecule --with "molecule-plugins[docker]" molecule

$(shell mkdir -p $(LOG_DIR) $(BACKUP_DIR) $(GALAXY_DIR))

# === Core Functions ===
run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>] [TAGS=<tags>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🚀 Running $(COLLECTION): $(PLAYBOOK)"
	@export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
	"$(SHIM_DIR)/ansible-playbook" -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \

check:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make check PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🔍 Checking $(COLLECTION): $(PLAYBOOK)"
	@export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG_ABS)" ]; then export ANSIBLE_CONFIG="$(CONFIG_ABS)"; fi; \
	"$(SHIM_DIR)/ansible-playbook" -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		--check --diff

secure:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make secure PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🔒 Secure execution: $(COLLECTION): $(PLAYBOOK)"
	@ulimit -c 0; \
	export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	export ANSIBLE_CONFIG="$(CONFIG_ABS)"; \
	export ANSIBLE_NO_LOG=true; \
	export ANSIBLE_FORCE_COLOR=false; \
	"$(SHIM_DIR)/ansible-playbook" -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \
		--ask-become-pass

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
	@export PATH="$(UV_BIN):$$PATH"; uv tool install --python $(UV_PY) ansible-lint
	@echo "🔧 Creating repo-local shims in $(SHIM_DIR) ..."
	@mkdir -p "$(SHIM_DIR)"
	@printf '%s\n' '#!/bin/sh' 'exec uvx --python $(UV_PY) --from "$(ANSIBLE_CORE_SPEC)" ansible "$$@"'          > "$(SHIM_DIR)/ansible";           chmod +x "$(SHIM_DIR)/ansible"
	@printf '%s\n' '#!/bin/sh' 'exec uvx --python $(UV_PY) --from "$(ANSIBLE_CORE_SPEC)" ansible-playbook "$$@"' > "$(SHIM_DIR)/ansible-playbook";   chmod +x "$(SHIM_DIR)/ansible-playbook"
	@printf '%s\n' '#!/bin/sh' 'exec uvx --python $(UV_PY) --from "$(ANSIBLE_CORE_SPEC)" ansible-galaxy "$$@"'   > "$(SHIM_DIR)/ansible-galaxy";     chmod +x "$(SHIM_DIR)/ansible-galaxy"
	@printf '%s\n' '#!/bin/sh' 'exec uvx --python $(UV_PY) --from "$(ANSIBLE_CORE_SPEC)" ansible-vault "$$@"'    > "$(SHIM_DIR)/ansible-vault";      chmod +x "$(SHIM_DIR)/ansible-vault"
	@echo "📦 Installing Galaxy collections to $(GALAXY_DIR) ..."
	@ANSIBLE_CONFIG="$(REPO_ROOT)/ansible.cfg" \
	ANSIBLE_GALAXY_CACHE_DIR="$(REPO_ROOT)/.vendor/.cache" \
	ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)" \
		"$(SHIM_DIR)/ansible-galaxy" collection install -p "$(GALAXY_DIR)" -r requirements-dev.yml
	@echo "✅ Ansible and Collections installed via uv"
	@echo "🔍 Verifying installation:"
	@env -i PATH="$(SHIM_DIR):/usr/bin:/bin:$(UV_BIN)" ansible --version | head -n1 || true
	@uvx --python $(UV_PY) --from ansible-lint ansible-lint --version || true
	@ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)" env -i PATH="$(SHIM_DIR):/usr/bin:/bin:$(UV_BIN)" ansible-galaxy collection list | grep yamisskey || true
	@echo "🧪 Molecule runtime (uvx) check:"
	@$(MOLECULE) --version && echo "✅ Molecule available via uvx" || echo "⚠️ Molecule check failed (ensure Docker is available)"

inventory:
	@if [ "$(TYPE)" = "local" ]; then \
		echo "📋 Creating self-provisioning inventory for current host..."; \
		INV_PATH="$(INV)"; \
		TEMPLATE_PATH="$(DEPLOY_DIR)/inventory.local.template"; \
		if [ ! -f "$$TEMPLATE_PATH" ]; then echo "❌ Local template not found: $$TEMPLATE_PATH"; exit 1; fi; \
		if [ -f "$$INV_PATH" ]; then echo "⚠️  Inventory already exists. Creating backup..."; cp "$$INV_PATH" "$(BACKUP_DIR)/$(TARGET)-inventory-local-$(TIMESTAMP).bak"; fi; \
		CURRENT_HOST=$$(hostname); CURRENT_USER=$$(whoami); \
		HOST_IP=$$(ip route get 1.1.1.1 | awk '{print $$7; exit}' 2>/dev/null || hostname -i 2>/dev/null | awk '{print $$1}' || echo "127.0.0.1"); \
		DOMAIN="$${DOMAIN:-yami.ski}"; NETWORK="$${INTERNAL_NETWORK:-192.168.0.0/24}"; HOST_ROLE="$${HOST_ROLE:-monitor}"; \
		echo "🖥️  Detected system information:"; \
		echo "   - Hostname: $$CURRENT_HOST"; echo "   - User: $$CURRENT_USER"; echo "   - IP: $$HOST_IP"; echo "   - Role: $$HOST_ROLE"; echo "   - Domain: $$DOMAIN"; \
		echo "📄 Processing local template..."; \
		cp "$$TEMPLATE_PATH" "$$INV_PATH"; \
		sed -i.bak -e "s|HOSTNAME_PLACEHOLDER|$$CURRENT_HOST|g" -e "s|USER_PLACEHOLDER|$$CURRENT_USER|g" -e "s|HOST_IP_PLACEHOLDER|$$HOST_IP|g" -e "s|DOMAIN_PLACEHOLDER|$$DOMAIN|g" -e "s|NETWORK_PLACEHOLDER|$$NETWORK|g" -e "s|HOST_ROLE_PLACEHOLDER|$$HOST_ROLE|g" -e "s|TIMESTAMP_PLACEHOLDER|$$(date)|g" -e "s|GENERATED_DATE_PLACEHOLDER|$$(date -Iseconds)|g" "$$INV_PATH"; \
		rm "$$INV_PATH.bak" 2>/dev/null || true; \
		echo "✅ Local inventory created at $$INV_PATH"; \
	else \
		echo "📋 Creating $(TARGET) inventory from template..."; \
		INV_PATH="$(INV)"; TEMPLATE_PATH="$(DEPLOY_DIR)/inventory.template"; \
		if [ ! -f "$$TEMPLATE_PATH" ]; then echo "❌ Template not found: $$TEMPLATE_PATH"; exit 1; fi; \
		if [ -f "$$INV_PATH" ]; then echo "⚠️  Inventory already exists. Creating backup..."; cp "$$INV_PATH" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak"; fi; \
		echo "📄 Processing template with Tailscale IPs..."; \
		cp "$$TEMPLATE_PATH" "$$INV_PATH"; \
		CURRENT_HOST=$$(hostname); CURRENT_USER=$$(whoami); DOMAIN="yami.ski"; NETWORK="100.64.0.0/10"; \
		BALTHASAR_IP=$$(tailscale ip -4 balthasar 2>/dev/null); CASPAR_IP=$$(tailscale ip -4 caspar 2>/dev/null); LINODE_IP=$$(tailscale ip -4 linode-prox 2>/dev/null); JOSEPH_IP=$$(tailscale ip -4 joseph 2>/dev/null); RASPBERRY_IP=$$(tailscale ip -4 raspberrypi 2>/dev/null); \
		if [ -z "$$BALTHASAR_IP" ] || [ -z "$$CASPAR_IP" ] || [ -z "$$LINODE_IP" ]; then echo "❌ Failed to resolve required Tailscale IPs. Check 'tailscale status'"; exit 1; fi; \
		if [ "$(TARGET)" = "servers" ] && [ -z "$$RASPBERRY_IP" ]; then echo "❌ raspberrypi not found in Tailscale"; exit 1; fi; \
		if [ "$(TARGET)" = "appliances" ] && [ -z "$$JOSEPH_IP" ]; then echo "❌ joseph not found in Tailscale"; exit 1; fi; \
		sed -i.bak -e "s|HOSTNAME_PLACEHOLDER|$$CURRENT_HOST|g" -e "s|DOMAIN_PLACEHOLDER|$$DOMAIN|g" -e "s|USER_PLACEHOLDER|$$CURRENT_USER|g" -e "s|BALTHASAR_IP_PLACEHOLDER|$$BALTHASAR_IP|g" -e "s|CASPAR_IP_PLACEHOLDER|$$CASPAR_IP|g" -e "s|LINODE_IP_PLACEHOLDER|$$LINODE_IP|g" -e "s|JOSEPH_IP_PLACEHOLDER|$$JOSEPH_IP|g" -e "s|RASPBERRY_IP_PLACEHOLDER|$$RASPBERRY_IP|g" -e "s|NETWORK_PLACEHOLDER|$$NETWORK|g" "$$INV_PATH"; \
		rm "$$INV_PATH.bak" 2>/dev/null || true; \
		echo "✅ $(TARGET) inventory created from template at $$INV_PATH"; \
		echo "💡 Next Steps: create & encrypt group_vars/vault.yml"; \
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
			RASPBERRY_IP=$$(tailscale ip -4 raspberrypi 2>/dev/null); \
			LINODE_IP=$$(tailscale ip -4 linode-prox 2>/dev/null); \
			[ -n "$$BALTHASAR_IP" ] && echo "   ✅ balthasar: $$BALTHASAR_IP" || echo "   ❌ balthasar: offline"; \
			[ -n "$$CASPAR_IP" ] && echo "   ✅ caspar: $$CASPAR_IP" || echo "   ❌ caspar: offline"; \
			[ -n "$$JOSEPH_IP" ] && echo "   ✅ joseph: $$JOSEPH_IP" || echo "   ❌ joseph: offline"; \
			[ -n "$$RASPBERRY_IP" ] && echo "   ✅ raspberrypi: $$RASPBERRY_IP" || echo "   ❌ raspberrypi: offline"; \
			[ -n "$$LINODE_IP" ] && echo "   ✅ linode-prox: $$LINODE_IP" || echo "   ❌ linode-prox: offline"; \
		else echo "   ❌ Tailscale disconnected"; fi \
	else echo "   ⚠️  Tailscale not installed"; fi
	@echo ""
	@echo "🗄️  Storage Services:"
	@if command -v curl >/dev/null 2>&1; then \
		echo -n "   MinIO (drive): "; \
		STATUS_CODE=$$(curl -s -w "%{http_code}" -o /dev/null --max-time 10 https://drive.yami.ski/minio/health/live 2>/dev/null); \
		if [ "$$STATUS_CODE" = "200" ]; then echo "✅ OK"; \
		elif [ "$$STATUS_CODE" = "403" ]; then echo "✅ OK (403 expected)"; \
		elif [ "$$STATUS_CODE" = "000" ]; then echo "❌ NO RESPONSE"; \
		else echo "⚠️  HTTP $$STATUS_CODE"; fi; \
	fi
	@echo ""
	@echo "📊 Monitoring Services:"
	@if command -v curl >/dev/null 2>&1; then \
		echo -n "   Grafana: "; \
		STATUS_CODE=$$(curl -s -w "%{http_code}" -o /dev/null --max-time 5 https://grafana.yami.ski/api/health 2>/dev/null); \
		if [ "$$STATUS_CODE" = "200" ]; then echo "✅ OK"; \
		elif [ "$$STATUS_CODE" = "000" ]; then echo "❌ NO RESPONSE"; \
		else echo "⚠️  HTTP $$STATUS_CODE"; fi; \
	fi

logs:
	@echo "📋 Recent logs:"
	@find $(LOG_DIR) -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "  No recent logs"

backup:
	@echo "💾 Backing up $(TARGET) inventory..."
	@test -f "$(INV)" && cp "$(INV)" "$(BACKUP_DIR)/$(TARGET)-inventory-$(TIMESTAMP).bak" || true
	@echo "✅ Backup created"

# === Testing (Molecule via uvx; docker required) ===
test:
	@ROLES_DIR="$(COLLECTIONS_DIR)/$(TARGET)/roles"; \
	MODE_EFF="$(MODE)"; [ -n "$$MODE_EFF" ] || MODE_EFF=test; \
	SUBCMD="test"; EXTRA=""; \
	case "$$MODE_EFF" in syntax) SUBCMD="syntax";; converge) SUBCMD="converge";; cleanup) SUBCMD="cleanup"; EXTRA="destroy || true";; test) SUBCMD="test";; *) echo "❌ Invalid MODE. Use: syntax, converge, cleanup, or test"; exit 1;; esac; \
	if ! command -v docker >/dev/null 2>&1; then echo "❌ Docker not found. Install & start docker."; exit 1; fi; \
	if ! docker info >/dev/null 2>&1; then echo "❌ Docker daemon is not running."; exit 1; fi; \
	export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	if [ -f "$(CONFIG)" ]; then export ANSIBLE_CONFIG="$(CONFIG)"; fi; \
	if [ -n "$(ROLE)" ]; then \
		ROLE_EFF="$(ROLE)"; [ "$$ROLE_EFF" = "modsecurity" ] && ROLE_EFF="modsecurity-nginx"; \
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
		for r in $$ROLES; do role_name=$$(basename "$$r"); echo "📋 Testing $$role_name..."; (cd "$$r" && $(MOLECULE) $$SUBCMD); if [ -n "$$EXTRA" ]; then (cd "$$r" && $(MOLECULE) $$EXTRA); fi; done; \
	fi

help:
	@echo "🚀 yamisskey-provision: Unified Ansible Infrastructure Management"
	@echo "================================================================="
	@echo ""
	@echo "📦 Setup & Installation"
	@echo "  make install                         Install uv toolchain + Galaxy collections"
	@echo "  make inventory [TARGET=servers]      Create inventory from template"
	@echo ""
	@echo "🔐 Secrets (SOPS)"
	@echo "  make sops-install                    Check/install SOPS and Age"
	@echo "  make sops-edit [TARGET=servers]      Edit encrypted secrets"
	@echo "  make sops-view [TARGET=servers]      View decrypted secrets"
	@echo "  make sops-status [TARGET=servers]    Validate secret configuration"
	@echo "  make sops-updatekeys [TARGET=servers] Rotate encryption recipients"
	@echo ""
	@echo "🔍 Discovery & Status"
	@echo "  make status                          Health check (Tailscale, DNS, services)"
	@echo "  make list [TARGET=servers]           List available playbooks"
	@echo ""
	@echo "🚀 Playbook Execution"
	@echo "  make run PLAYBOOK=<name>             Standard execution with sudo"
	@echo "  make secure PLAYBOOK=<name>          Secure execution (memory protection)"
	@echo "  make deploy PLAYBOOKS='p1 p2'        Sequential multi-playbook deployment"
	@echo ""
	@echo "🧪 Testing & Validation"
	@echo "  make check PLAYBOOK=<name>           Dry-run with diff preview"
	@echo "  make test ROLE=<name> MODE=syntax    Molecule testing (syntax|converge|test)"
	@echo ""
	@echo "🗄️ Maintenance"
	@echo "  make backup [TARGET=servers]         Backup current inventory"
	@echo "  make logs                            View recent log files"
	@echo ""
	@echo "⚙️ Common Usage Examples"
	@echo "  make sops-edit TARGET=servers               # Edit server secrets"
	@echo "  make sops-status TARGET=appliances          # Verify appliance secrets"
	@echo "  make run PLAYBOOK=common LIMIT=caspar        # Run common setup on caspar"
	@echo "  make secure PLAYBOOK=monitor LIMIT=caspar    # Secure monitor deployment"
	@echo "  make check PLAYBOOK=security TARGET=servers  # Preview security changes"
	@echo "  make deploy PLAYBOOKS='common security'      # Multi-stage deployment"
	@echo ""
	@echo "📋 Environment Variables"
	@echo "  TARGET     servers|appliances (default: servers)"
	@echo "  LIMIT      Restrict to specific hosts (e.g., caspar,balthasar)"
	@echo "  TAGS       Run specific tags only (e.g., install,config)"
	@echo "  PLAYBOOK   Single playbook name"
	@echo "  PLAYBOOKS  Space-separated playbook list for deploy"
