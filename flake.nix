{
  description = "yamisskey-provision: Modern Ansible infrastructure with SOPS secrets management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Python environment with Ansible and related tools
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          ansible-core
          molecule
          docker
          pytest
          pytest-ansible
          yamllint
          jinja2
          pyyaml
          cryptography
          requests
        ]);
        
        # Role-based package sets for modular management
        rolePackages = {
          # Core system utilities (always included)
          base = with pkgs; [
            curl
            wget
            openssh
            git
            nettools
            nmap
            dnsutils
            htop
            btop
            sysstat
            lynis
            jq
            yq-go
            unzip
            zip
            tar
            gawk
            gnused
            findutils
            coreutils
            rsync
            lsof
            tmux
          ];

          # Common role packages
          common = with pkgs; [
            prometheus
            rclone
            apparmor
            auditd
            tor
            go
          ];

          # Security role packages
          security = with pkgs; [
            fail2ban
            ufw
            dnscrypt-proxy
            clamav
          ];

          # Watch/monitoring role packages
          watch = with pkgs; [
            prometheus-node-exporter
          ];

          # AI role packages
          ai = with pkgs; [
            mecab
            mecab-ipadic
            python3
            python3Packages.pip
          ];

          # GHQ role packages
          ghq = with pkgs; [
            ghq
          ];

          # Development/control node packages
          development = with pkgs; [
            ansible_2_17
            ansible-lint
            pythonEnv
            yamllint
            sops
            age
            gnupg
            docker
            docker-compose
            python3Packages.passlib
            nixpkgs-fmt
            statix
          ];

          # Infrastructure services
          infrastructure = with pkgs; [
            cloudflared
            tailscale
          ];
        };

        # Helper function to combine role packages
        mkRoleConfig = rolesToInclude:
          let
            selectedPackages = builtins.concatLists (
              builtins.map (role: rolePackages.${role}) rolesToInclude
            );
          in {
            home.packages = rolePackages.base ++ selectedPackages;
            home.stateVersion = "23.11";
          };

        # Home Manager configurations based on role combinations
        homeConfigurations = {
          # Development/control node
          development = mkRoleConfig [
            "common" "security" "watch" "ghq" "development" "infrastructure"
          ];
          
          # Standard production server
          server = mkRoleConfig [
            "common" "security" "watch" "infrastructure"
          ];
          
          # AI/ML server
          ai-server = mkRoleConfig [
            "common" "security" "watch" "ai" "infrastructure"
          ];

          # Minimal server (only base + common)
          minimal = mkRoleConfig [
            "common"
          ];

          # Security-focused server
          security-server = mkRoleConfig [
            "common" "security" "watch" "infrastructure"
          ];
        };

      in
      let
        packages' = let
          mkCommand = name: script: pkgs.writeShellScriptBin name script;
          
          baseEnv = ''
            export ANSIBLE_COLLECTIONS_PATH="$PWD"
            export ANSIBLE_FORCE_COLOR="1"
            export ANSIBLE_HOST_KEY_CHECKING="False"
            export PYTHONPATH="$PWD"
            mkdir -p logs backups .vendor/collections
          '';
          
        in {
          # Main unified command
          default = mkCommand "yamisskey-provision" ''
            set -euo pipefail
            ${baseEnv}
            
            COMMAND=$1; shift || true
            
            case "$COMMAND" in
              # SOPS operations
              sops)
                OPERATION=$1; shift || true
                TARGET=''${1:-servers}
                case "$OPERATION" in
                  install)
                    if command -v sops >/dev/null 2>&1 && command -v age >/dev/null 2>&1; then
                      echo "✅ SOPS and Age already available (sops: $(command -v sops))"
                    elif command -v nix >/dev/null 2>&1; then
                      echo "🚀 Installing SOPS and Age via nix profile..."
                      nix profile install nixpkgs#sops nixpkgs#age >/dev/null 2>&1 && \
                        echo "✅ Installed SOPS and Age using nix profile" || \
                        { echo "❌ Failed to install SOPS/Age via nix"; exit 1; }
                    else
                      echo "❌ SOPS not installed and nix unavailable. Install SOPS and Age via your OS package manager or use 'nix develop'."
                      exit 1
                    fi ;;
                  edit)
                    VAULT_FILE="deploy/$TARGET/group_vars/vault.yml"
                    [ -f "$VAULT_FILE" ] || { echo "❌ vault.yml not found"; exit 1; }
                    sops "$VAULT_FILE" ;;
                  view)
                    VAULT_FILE="deploy/$TARGET/group_vars/vault.yml"
                    [ -f "$VAULT_FILE" ] || { echo "❌ vault.yml not found"; exit 1; }
                    sops -d "$VAULT_FILE" ;;
                  status)
                    echo "📊 SOPS Status Check for $TARGET"
                    echo "=================================="
                    command -v sops >/dev/null && echo "✅ SOPS: $(sops --version --check-for-updates)" || echo "❌ SOPS: NOT INSTALLED"
                    command -v age >/dev/null && echo "✅ Age: $(age --version)" || echo "❌ Age: NOT INSTALLED"
                    [ -f ".sops.yaml" ] && echo "✅ .sops.yaml: CONFIGURED" || echo "❌ .sops.yaml: NOT FOUND"
                    VAULT_FILE="deploy/$TARGET/group_vars/vault.yml"
                    if [ -f "$VAULT_FILE" ]; then
                      sops -d "$VAULT_FILE" >/dev/null 2>&1 && echo "✅ vault.yml: SOPS ENCRYPTED" || echo "⚠️  vault.yml: NOT SOPS ENCRYPTED"
                    else
                      echo "❌ vault.yml: NOT FOUND"
                    fi ;;
                  *) echo "Usage: yp sops {install|edit|view|status} [target]"; exit 1 ;;
                esac ;;
              
              # Ansible operations
              run)
                PLAYBOOK=$1; shift || true
                TARGET=''${1:-servers}
                LIMIT=$2
                [ -n "$PLAYBOOK" ] || { echo "Usage: yp run <playbook> [target] [limit]"; exit 1; }
                
                DEPLOY_DIR="deploy/$TARGET"
                [ -f "$DEPLOY_DIR/playbooks/$PLAYBOOK.yml" ] || { echo "❌ Playbook $PLAYBOOK.yml not found"; exit 1; }
                
                echo "🚀 Running $TARGET: $PLAYBOOK"
                [ -f "$DEPLOY_DIR/ansible.cfg" ] && export ANSIBLE_CONFIG="$PWD/$DEPLOY_DIR/ansible.cfg"
                ansible-playbook -i "$DEPLOY_DIR/inventory" "$DEPLOY_DIR/playbooks/$PLAYBOOK.yml" ''${LIMIT:+--limit $LIMIT} ;;
              
              check)
                PLAYBOOK=$1; shift || true
                TARGET=''${1:-servers}
                LIMIT=$2
                [ -n "$PLAYBOOK" ] || { echo "Usage: yp check <playbook> [target] [limit]"; exit 1; }
                
                DEPLOY_DIR="deploy/$TARGET"
                [ -f "$DEPLOY_DIR/playbooks/$PLAYBOOK.yml" ] || { echo "❌ Playbook $PLAYBOOK.yml not found"; exit 1; }
                
                echo "🔍 Checking $TARGET: $PLAYBOOK"
                [ -f "$DEPLOY_DIR/ansible.cfg" ] && export ANSIBLE_CONFIG="$PWD/$DEPLOY_DIR/ansible.cfg"
                ansible-playbook -i "$DEPLOY_DIR/inventory" "$DEPLOY_DIR/playbooks/$PLAYBOOK.yml" ''${LIMIT:+--limit $LIMIT} --check --diff ;;
              
              # Inventory management
              inventory)
                TARGET=''${1:-servers}
                TYPE=$2
                
                DEPLOY_DIR="deploy/$TARGET"
                INV_PATH="$DEPLOY_DIR/inventory"
                
                if [ "$TYPE" = "local" ]; then
                  TEMPLATE_PATH="$DEPLOY_DIR/inventory.example.local"
                  echo "📋 Creating self-provisioning inventory..."
                else
                  TEMPLATE_PATH="$DEPLOY_DIR/inventory.example"
                  echo "📋 Creating $TARGET inventory from template..."
                fi
                
                [ -f "$TEMPLATE_PATH" ] || { echo "❌ Template not found: $TEMPLATE_PATH"; exit 1; }
                
                if [ -f "$INV_PATH" ]; then
                  TIMESTAMP=$(date +%Y%m%dT%H%M%S)
                  cp "$INV_PATH" "backups/$TARGET-inventory-$TIMESTAMP.bak"
                  echo "⚠️  Backup created: backups/$TARGET-inventory-$TIMESTAMP.bak"
                fi
                
                cp "$TEMPLATE_PATH" "$INV_PATH"
                echo "✅ $TARGET inventory created" ;;
              
              # Status and discovery
              status)
                echo "🔍 Infrastructure Status Check"
                echo "==============================="
                ping -c 1 -W 3 yami.ski >/dev/null 2>&1 && echo "✅ yami.ski reachable" || echo "❌ yami.ski unreachable"
                command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1 && echo "✅ Tailscale connected" || echo "❌ Tailscale disconnected" ;;
              
              list)
                TARGET=''${1:-servers}
                echo "📋 Available $TARGET playbooks:"
                ls "deploy/$TARGET/playbooks"/*.yml 2>/dev/null | sed 's|.*/||; s|\.yml$||' | sort | sed 's/^/  /' ;;
              
              # Testing
              test)
                ROLE=$1
                MODE=''${2:-test}
                TARGET=''${3:-servers}
                [ -n "$ROLE" ] || { echo "Usage: yp test <role> [mode] [target]"; exit 1; }
                
                command -v docker >/dev/null || { echo "❌ Docker required for testing"; exit 1; }
                docker info >/dev/null 2>&1 || { echo "❌ Docker daemon not running"; exit 1; }
                
                ROLE_DIR="ansible_collections/yamisskey/$TARGET/roles/$ROLE"
                [ -d "$ROLE_DIR" ] || { echo "❌ Role not found: $ROLE"; exit 1; }
                [ -f "$ROLE_DIR/molecule/default/molecule.yml" ] || { echo "❌ Molecule config missing for $ROLE"; exit 1; }
                
                echo "🧪 Testing $TARGET/$ROLE with mode: $MODE"
                (cd "$ROLE_DIR" && molecule "$MODE") ;;
              
              # Maintenance
              backup)
                TARGET=''${1:-servers}
                TIMESTAMP=$(date +%Y%m%dT%H%M%S)
                [ -f "deploy/$TARGET/inventory" ] && cp "deploy/$TARGET/inventory" "backups/$TARGET-inventory-$TIMESTAMP.bak"
                echo "✅ Backup created: backups/$TARGET-inventory-$TIMESTAMP.bak" ;;
              
              logs)
                echo "📋 Recent logs:"
                find logs -name "*.log" -mtime -1 2>/dev/null | head -3 | xargs tail -20 2>/dev/null || echo "No recent logs" ;;
              
              # Help
              help|"")
                echo "🚀 yamisskey-provision: Modern Ansible Infrastructure with SOPS"
                echo "================================================================"
                echo ""
                echo "Usage: yamisskey-provision <command> [options]"
                echo ""
                echo "🔐 SOPS Secrets Management:"
                echo "  yamisskey-provision sops install                    Install SOPS and Age"
                echo "  yamisskey-provision sops edit [target]              Edit encrypted secrets"
                echo "  yamisskey-provision sops view [target]              View decrypted secrets"
                echo "  yamisskey-provision sops status [target]            Check SOPS status"
                echo ""
                echo "🚀 Ansible Operations:"
                echo "  yamisskey-provision run <playbook> [target] [limit] Run playbook"
                echo "  yamisskey-provision check <playbook> [target]       Dry-run with diff"
                echo ""
                echo "🔧 Infrastructure Management:"
                echo "  yamisskey-provision inventory [target] [type]       Create inventory"
                echo "  yamisskey-provision status                          Health check"
                echo "  yamisskey-provision list [target]                   List playbooks"
                echo ""
                echo "🧪 Testing & Maintenance:"
                echo "  yamisskey-provision test <role> [mode] [target]     Test role with molecule"
                echo "  yamisskey-provision backup [target]                 Backup inventory"
                echo "  yamisskey-provision logs                            View recent logs"
                echo ""
                echo "Examples:"
                echo "  yamisskey-provision sops edit servers               # Edit server secrets"
                echo "  yamisskey-provision run common servers caspar       # Run common on caspar"
                echo "  yamisskey-provision check security servers          # Preview security changes"
                echo "  yamisskey-provision test cloudflare_warp syntax     # Test role syntax"
                ;;
              
              *) echo "Unknown command: $COMMAND. Use 'yamisskey-provision help' for usage."; exit 1 ;;
            esac
          '';
          
          # Individual commands for backward compatibility
          sops-install = mkCommand "sops-install" ''${self.packages.${system}.default}/bin/yamisskey-provision sops install "$@"'';
          sops-edit = mkCommand "sops-edit" ''${self.packages.${system}.default}/bin/yamisskey-provision sops edit "$@"'';
          sops-view = mkCommand "sops-view" ''${self.packages.${system}.default}/bin/yamisskey-provision sops view "$@"'';
          sops-status = mkCommand "sops-status" ''${self.packages.${system}.default}/bin/yamisskey-provision sops status "$@"'';
          
          ansible-run = mkCommand "ansible-run" ''${self.packages.${system}.default}/bin/yamisskey-provision run "$@"'';
          ansible-check = mkCommand "ansible-check" ''${self.packages.${system}.default}/bin/yamisskey-provision check "$@"'';
          
          inventory-create = mkCommand "inventory-create" ''${self.packages.${system}.default}/bin/yamisskey-provision inventory "$@"'';
          cleanup-legacy = mkCommand "cleanup-legacy" ''rm -rf .bin .vendor && echo "✅ Legacy cleanup complete"'';
        };
      in {
        # Development shell - minimal for Ansible control
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core Ansible toolchain only
            ansible_2_17
            ansible-lint
            pythonEnv
            
            # SOPS secrets management
            sops
            age
            gnupg
            
            # Basic development tools
            yamllint
            jq
            yq-go
            git
            
            # Container testing
            docker
            docker-compose
            
            # Nix development
            nixpkgs-fmt
            statix
          ] ++ [ packages'.default ];

          shellHook = ''
            # Fix locale issues
            export LANG=C.UTF-8
            export LC_ALL=C.UTF-8
            
            echo "🚀 yamisskey-provision development environment (Nix Flake)"
            echo "=========================================================="
            echo ""
            echo "📦 Available tools:"
            echo "   ansible: $(ansible --version | head -1)"
            echo "   sops: $(sops --version --check-for-updates)"
            echo "   age: $(age --version)"
            echo "   ansible-lint: $(ansible-lint --version)"
            echo "   python: $(python3 --version)"
            
            # Set up environment variables
            export ANSIBLE_COLLECTIONS_PATH="$PWD"
            export ANSIBLE_FORCE_COLOR="1"
            export ANSIBLE_HOST_KEY_CHECKING="False"
            export PYTHONPATH="$PWD"
            
            # Create necessary directories
            mkdir -p logs backups .vendor/collections
          '';
          
          ANSIBLE_FORCE_COLOR = "1";
          ANSIBLE_HOST_KEY_CHECKING = "False";
          LANG = "C.UTF-8";
          LC_ALL = "C.UTF-8";
        };
        
        formatter = pkgs.nixpkgs-fmt;
        
        # Unified command interface - maintains Makefile simplicity
        packages = packages';
      }
    );
}
