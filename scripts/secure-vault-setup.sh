jjjj#!/bin/bash
# ========================================
# Secure Ansible Vault Setup Script
# ========================================
# vault passwordの単一障害点を軽減する対策

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ========================================
# 1. 複数のvault password対策
# ========================================
setup_vault_rotation() {
    info "Setting up vault password rotation..."
    
    # Primary vault password
    if [[ ! -f "${PROJECT_ROOT}/.vault_pass" ]]; then
        warn "Primary vault password not found. Creating..."
        openssl rand -base64 32 > "${PROJECT_ROOT}/.vault_pass"
        chmod 600 "${PROJECT_ROOT}/.vault_pass"
    fi
    
    # Backup vault password (for rotation)
    if [[ ! -f "${PROJECT_ROOT}/.vault_pass.backup" ]]; then
        info "Creating backup vault password for rotation..."
        openssl rand -base64 32 > "${PROJECT_ROOT}/.vault_pass.backup"
        chmod 600 "${PROJECT_ROOT}/.vault_pass.backup"
    fi
    
    info "✅ Vault password rotation setup complete"
}

# ========================================
# 2. メモリ上の平文対策
# ========================================
setup_memory_protection() {
    info "Setting up memory protection..."
    
    # メモリダンプ無効化の警告
    warn "Memory protection recommendations:"
    echo "  1. Disable core dumps: ulimit -c 0"
    echo "  2. Disable swap: swapoff -a (for production)"
    echo "  3. Use encrypted swap if swap is needed"
    echo "  4. Consider using systemd's NoNewPrivileges=true"
    
    # 実行時メモリ保護のための環境変数設定
    cat > "${PROJECT_ROOT}/.env.secure" << 'EOF'
# Memory protection settings
export ANSIBLE_VAULT_PASSWORD_FILE=""
export ANSIBLE_ASK_VAULT_PASS="true"
export ANSIBLE_FORCE_COLOR="false"
export ANSIBLE_NO_LOG="true"
EOF
    
    chmod 600 "${PROJECT_ROOT}/.env.secure"
    info "✅ Memory protection setup complete"
}

# ========================================
# 3. ログ漏洩対策
# ========================================
setup_log_protection() {
    info "Setting up log protection..."
    
    # セキュアなログ設定
    mkdir -p "${PROJECT_ROOT}/logs/secure"
    chmod 700 "${PROJECT_ROOT}/logs/secure"
    
    # .gitignoreにセキュアログディレクトリを追加
    if ! grep -q "logs/secure" "${PROJECT_ROOT}/.gitignore" 2>/dev/null; then
        echo "logs/secure/" >> "${PROJECT_ROOT}/.gitignore"
    fi
    
    # logrotateの設定
    cat > "${PROJECT_ROOT}/scripts/ansible-logrotate.conf" << 'EOF'
/home/*/yamisskey-provision/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 600 $(whoami) $(whoami)
    postrotate
        # メモリ内のログバッファをクリア
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    endscript
}
EOF
    
    info "✅ Log protection setup complete"
}

# ========================================
# 4. デバッグ時露出対策
# ========================================
setup_debug_protection() {
    info "Setting up debug protection..."
    
    # セキュアなデバッグ設定用ansible.cfg
    cat > "${PROJECT_ROOT}/deploy/servers/ansible.cfg.debug" << 'EOF'
[defaults]
roles_path = ../../ansible_collections/yamisskey/servers/roles
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = ansible.builtin.default
bin_ansible_callbacks = True
remote_tmp = /tmp/ansible
# デバッグ時のセキュリティ強化
no_log = True
display_skipped_hosts = False
display_ok_hosts = False
any_errors_fatal = True
gather_subset = min

[inventory]
enable_plugins = host_list, script, auto, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o Ciphers=aes256-ctr,aes192-ctr,aes128-ctr
pipelining = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[persistent_connection]
connect_timeout = 30
connect_retries = 3
EOF
    
    info "✅ Debug protection setup complete"
}

# ========================================
# 5. Makefileセキュリティ強化
# ========================================
update_makefile_security() {
    info "Updating Makefile with security enhancements..."
    
    # セキュアな実行用のターゲットを追加するためのパッチファイル作成
    cat > "${PROJECT_ROOT}/scripts/makefile-security.patch" << 'EOF'
# セキュア実行用の新しいターゲット
secure-run:
	@test -n "$(PLAYBOOK)" || (echo "❌ Usage: make secure-run PLAYBOOK=<name> [TARGET=servers|appliances] [LIMIT=<hosts>]" && exit 1)
	@test -f "$(PLAY)/$(PLAYBOOK).yml" || (echo "❌ Playbook $(PLAYBOOK).yml not found in $(PLAY)/" && exit 1)
	@echo "🔒 Secure execution: $(COLLECTION): $(PLAYBOOK)"
	@# メモリ保護の適用
	@ulimit -c 0; \
	export ANSIBLE_COLLECTIONS_PATH="$(ANSIBLE_PATHS)"; \
	export ANSIBLE_CONFIG="$(CONFIG_ABS)"; \
	export ANSIBLE_NO_LOG=true; \
	export ANSIBLE_FORCE_COLOR=false; \
	"$(SHIM_DIR)/ansible-playbook" -i "$(INV)" "$(PLAY)/$(PLAYBOOK).yml" \
		$(if $(LIMIT),--limit $(LIMIT)) \
		$(if $(TAGS),--tags $(TAGS)) \
		--ask-vault-pass \
		--ask-become-pass

# vault password rotation用のターゲット
rotate-vault:
	@echo "🔄 Rotating vault password..."
	@if [ -f "$(DEPLOY_DIR)/group_vars/vault.yml" ]; then \
		echo "Creating backup of current vault..."; \
		cp "$(DEPLOY_DIR)/group_vars/vault.yml" "$(BACKUP_DIR)/vault-$(TIMESTAMP).bak"; \
		echo "Rotating vault password..."; \
		ansible-vault rekey "$(DEPLOY_DIR)/group_vars/vault.yml"; \
		echo "✅ Vault password rotated successfully"; \
	else \
		echo "❌ vault.yml not found"; \
		exit 1; \
	fi
EOF
    
    info "✅ Makefile security enhancements prepared"
}

# ========================================
# メイン実行
# ========================================
main() {
    info "🔒 Starting secure Ansible Vault setup..."
    
    setup_vault_rotation
    setup_memory_protection
    setup_log_protection
    setup_debug_protection
    update_makefile_security
    
    info "🎉 Secure setup complete!"
    
    warn "Manual steps required:"
    echo "  1. Source secure environment: source .env.secure"
    echo "  2. Create vault.yml: cp deploy/servers/group_vars/vault.yml.example deploy/servers/group_vars/vault.yml"
    echo "  3. Edit vault.yml with actual values"
    echo "  4. Encrypt vault: ansible-vault encrypt deploy/servers/group_vars/vault.yml"
    echo "  5. Test with: make secure-run PLAYBOOK=monitor LIMIT=caspar"
    echo ""
    info "For enhanced security, consider:"
    echo "  - Using external secret management (HashiCorp Vault, AWS Secrets Manager)"
    echo "  - Implementing vault password rotation schedule"
    echo "  - Monitoring for unauthorized vault access"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi