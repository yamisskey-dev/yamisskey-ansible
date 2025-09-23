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
    # Note: Environment variables are managed by direnv (.envrc)
    # This shell only provides packages - see .envrc for configuration
    echo "📦 Nix shell activated. Environment managed by direnv (.envrc)"
  '';
}
