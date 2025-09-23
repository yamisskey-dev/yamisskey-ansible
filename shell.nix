# Nix development shell for yamisskey-provision
# Provides Ansible, SOPS, Age, and all dependencies
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core Ansible toolchain
    ansible_2_17  # Stable version
    ansible-lint
    
    # SOPS secrets management
    sops
    age
    gnupg  # For PGP support
    
    # Development tools
    python3
    python3Packages.pip
    python3Packages.virtualenv
    
    # Container and testing
    docker
    molecule  # For role testing
    
    # Utilities
    curl
    jq
    yq-go
    git
    
    # Molecule dependencies
    python3Packages.molecule
    python3Packages.docker
  ];

  shellHook = ''
    echo "🚀 yamisskey-provision development environment"
    echo "=============================================="
    echo ""
    echo "📦 Available tools:"
    echo "   ansible: $(ansible --version | head -1)"
    echo "   sops: $(sops --version --check-for-updates)"
    echo "   age: $(age --version)"
    echo "   ansible-lint: $(ansible-lint --version)"
    
    # Set up environment
    export ANSIBLE_COLLECTIONS_PATH="$PWD"
    export PATH="$PWD/.bin:$PATH"
    
    # Create necessary directories
    mkdir -p logs backups .vendor/collections
  '';
  
  # Environment variables
  ANSIBLE_FORCE_COLOR = "1";
  ANSIBLE_HOST_KEY_CHECKING = "False";
  PYTHONPATH = "$PWD";
}
