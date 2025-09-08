.PHONY: all install inventory clone migrate test provision help

DESTINATION_SSH_USER=$(shell whoami)
DESTINATION_HOSTNAME=$(shell hostname)
DESTINATION_IP=$(shell tailscale status | grep $(DESTINATION_HOSTNAME) | awk '{print $$1}')
DESTINATION_SSH_PORT=22
OS=$(shell lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(shell lsb_release -cs)
ARCH=$(shell dpkg --print-architecture)
USER=$(shell whoami)
TIMESTAMP=$(shell date +%Y%m%dT%H%M%S`date +%N | cut -c 1-6`)
GITHUB_ORG=yamisskey-dev
GITHUB_ORG_URL=https://github.com/$(GITHUB_ORG)
MISSKEY_REPO=$(GITHUB_ORG_URL)/yamisskey.git
MISSKEY_DIR=/var/www/misskey
MISSKEY_BRANCH=master
CONFIG_FILES=$(MISSKEY_DIR)/.config/default.yml $(MISSKEY_DIR)/.config/docker.env
AI_DIR=$(HOME)/ai
BACKUP_SCRIPT_DIR=/opt/misskey-backup
ANONOTE_DIR=$(HOME)/misskey-anonote
ASSETS_DIR=$(HOME)/misskey-assets
CTFD_DIR=$(HOME)/ctfd
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
	@ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/setup.yml --ask-become-pass

ap-migrate:
	@ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-truenas.yml --ask-become-pass

ap-e2e:
	@ansible-playbook -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/truenas-minio-deploy-and-migrate.yml --ask-become-pass

ap-syntax:
	@ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/setup.yml || true
	@ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/truenas-minio-deploy-and-migrate.yml || true
	@ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-truenas.yml
	@ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-phase-a.yml
	@ansible-playbook --syntax-check -i $(APPLIANCES_INV) $(APPLIANCES_PLAY)/migrate-minio-cutover.yml

all: sv-install sv-inventory sv-clone sv-provision

sv-install:
	@echo "Installing Ansible..."
	@sudo apt-get update && sudo apt-get install -y ansible || (echo "Install failed" && exit 1)
	@echo "Installing Ansible collections..."
	@ansible-galaxy collection install -r $(SERVERS_DIR)/requirements.yml
	@echo "Installing necessary packages..."
	@ansible-playbook -i $(SERVERS_INV) --limit source $(SERVERS_PLAY)/common.yml --ask-become-pass
	@echo "Installing Tailscale..."
	@curl -fsSL https://tailscale.com/install.sh | sh
	@echo "Installing Cloudflare Warp..."
	@curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
	@echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(CODENAME) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
	@sudo apt-get update && sudo apt-get install -y cloudflare-warp
	@echo "Installing Cloudflared..."
	@wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(ARCH).deb
	@sudo dpkg -i cloudflared-linux-$(ARCH).deb
	@rm -f cloudflared-linux-$(ARCH).deb
	@echo "Installing Docker..."
	@sudo install -m 0755 -d /etc/apt/keyrings
	@sudo curl -fsSL https://download.docker.com/linux/$(OS)/gpg -o /etc/apt/keyrings/docker.asc
	@sudo chmod a+r /etc/apt/keyrings/docker.asc
	@echo "deb [arch=$(ARCH) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(OS) $(CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	@sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || (echo "Docker installation failed" && exit 1)
	@curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
	@echo "Installing Playit..."
	@echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list
	@sudo apt update
	@sudo apt install playit

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

sv-clone:
	@echo "Cloning repositories if not already present..."
	@sudo mkdir -p $(MISSKEY_DIR)
	@sudo chown $(USER):$(USER) $(MISSKEY_DIR)
	@if [ ! -d "$(MISSKEY_DIR)/.git" ]; then \
		git clone $(MISSKEY_REPO) $(MISSKEY_DIR); \
		cd $(MISSKEY_DIR) && git checkout $(MISSKEY_BRANCH); \
	fi
	@sudo mkdir -p $(ASSETS_DIR)
	@sudo chown $(USER):$(USER) $(ASSETS_DIR)
	@if [ ! -d "$(ASSETS_DIR)/.git" ]; then \
		git clone $(GITHUB_ORG_URL)/yamisskey-assets.git $(ASSETS_DIR); \
	fi
	@mkdir -p $(AI_DIR)
	@if [ ! -d "$(AI_DIR)/.git" ]; then \
		git clone $(GITHUB_ORG_URL)/yui.git $(AI_DIR); \
	fi
	@mkdir -p $(BACKUP_SCRIPT_DIR)
	@if [ ! -d "$(BACKUP_SCRIPT_DIR)/.git" ]; then \
		git clone $(GITHUB_ORG_URL)/yamisskey-backup.git $(BACKUP_SCRIPT_DIR); \
	fi
	@mkdir -p $(ANONOTE_DIR)
	@if [ ! -d "$(ANONOTE_DIR)/.git" ]; then \
		git clone $(GITHUB_ORG_URL)/yamisskey-anonote.git $(ANONOTE_DIR); \
	fi
	@mkdir -p $(CTFD_DIR)
	@if [ ! -d "$(CTFD_DIR)/.git" ]; then \
		git clone $(GITHUB_ORG_URL)/ctf.yami.ski.git $(CTFD_DIR); \
	fi

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

sv-test:
	@echo "🧪 === MinIO Migration System Test ==="
	@echo ""
	@echo "🔍 Test 1: Basic inventory generation..."
	@$(MAKE) sv-inventory > /dev/null 2>&1
	@if [ -f $(SERVERS_INV) ]; then \
		echo "✅ Default inventory created successfully"; \
		echo "📄 Contents preview:"; \
		cat $(SERVERS_INV) | head -10; \
	else \
		echo "❌ Default inventory creation failed"; \
	fi
	@echo ""
	@echo "🔍 Test 2: Migration inventory generation..."
	@$(MAKE) sv-inventory SOURCE=balthasar TARGET=raspberrypi > /dev/null 2>&1
	@if [ -f $(SERVERS_INV) ]; then \
		echo "✅ Migration inventory created successfully"; \
		echo "📄 Contents preview:"; \
		cat $(SERVERS_INV) | head -10; \
	else \
		echo "❌ Migration inventory creation failed"; \
	fi
	@echo ""
	@echo "🔍 Test 3: Tailscale status check..."
	@if command -v tailscale >/dev/null 2>&1; then \
		echo "🌐 Tailscale network status:"; \
		tailscale status | head -5; \
		echo "✅ Tailscale available"; \
	else \
		echo "⚠️  Tailscale not installed (expected in development)"; \
	fi
	@echo ""
	@echo "🔍 Test 4: Ansible availability..."
	@if command -v ansible >/dev/null 2>&1; then \
		echo "🤖 Ansible version:"; \
		ansible --version | head -1; \
		echo "✅ Ansible available"; \
	else \
		echo "❌ Ansible not available"; \
	fi
	@echo ""
	@echo "🔍 Test 5: Check migrate role structure..."
	@if [ -d $(SERVERS_DIR)/roles/migrate ]; then \
		echo "✅ Migrate role directory exists"; \
		echo "📁 Role structure:"; \
		ls -la $(SERVERS_DIR)/roles/migrate/; \
	else \
		echo "❌ Migrate role directory missing"; \
	fi
	@echo ""
	@echo "🔍 Test 6: Progress monitoring features..."
	@if [ -f $(SERVERS_DIR)/roles/migrate/tasks/main.yml ]; then \
		echo "✅ Migration tasks file exists"; \
		if grep -q "async:"$(SERVERS_DIR)/roles/migrate/tasks/main.yml; then \
			echo "✅ Async execution with progress monitoring enabled"; \
		else \
			echo "⚠️  Progress monitoring not configured"; \
		fi; \
		if grep -q "poll:" $(SERVERS_DIR)/roles/migrate/tasks/main.yml; then \
			echo "✅ Polling intervals configured for real-time updates"; \
		else \
			echo "⚠️  Polling not configured"; \
		fi; \
	else \
		echo "❌ Migration tasks file missing"; \
	fi
	@echo ""
	@echo "🔍 Test 7: README and Makefile consistency check..."
	@echo "📖 README commands found:"
	@grep -n "make " $(SERVERS_DIR)/roles/migrate/README.md | head -5
	@echo ""
	@echo "🛠️  Makefile targets available:"
	@$(MAKE) help | grep -E "(inventory|migrate)"
	@echo ""
	@echo "🎯 === Test Summary ==="
	@echo "✅ = Pass, ❌ = Fail, ⚠️ = Warning"
	@echo ""
	@echo "🚀 To perform actual migration:"
	@echo "1. make migrate SOURCE=balthasar TARGET=raspberrypi"
	@echo "2. Ensure both hosts are accessible via Tailscale"
	@echo "3. Verify /opt/minio/secrets.yml exists on both hosts"
	@echo "4. Monitor progress through real-time updates every 10 seconds"

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
	@echo "Servers:"
	@echo "  sv-install    - Update and install necessary packages"
	@echo "  sv-inventory  - Create servers inventory (MODE=migration for migration)"
	@echo "  sv-clone      - Clone the repositories if they don't exist"
	@echo "  sv-provision  - Provision the server using Ansible"
	@echo "  sv-migrate    - Migrate MinIO data with encryption and progress monitoring"
	@echo "  sv-test       - Test migration system functionality with enhanced checks"
	@echo "  sv-transfer   - Transfer complete system using export/import playbooks"
	@echo ""
