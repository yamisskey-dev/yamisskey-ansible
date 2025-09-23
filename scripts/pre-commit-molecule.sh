#!/bin/bash

# Pre-commit hook for Molecule syntax checking
# This script runs Molecule syntax check only on changed Ansible roles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 Running Molecule pre-commit checks...${NC}"

# Get the list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# Extract unique role paths from staged files
CHANGED_ROLES=$(echo "$STAGED_FILES" | grep -E '^ansible_collections/.*/roles/' | cut -d'/' -f1-4 | sort -u || true)

if [ -z "$CHANGED_ROLES" ]; then
    echo -e "${GREEN}✅ No Ansible roles changed, skipping Molecule checks${NC}"
    exit 0
fi

# Check if necessary tools are available
if ! command -v molecule >/dev/null 2>&1; then
    echo -e "${RED}❌ Molecule not found. Please install Molecule first:${NC}"
    echo "   direnv allow  # Auto-loads Nix environment with Molecule"
    exit 1
fi

# Always use the Nix-enabled base image for local Molecule runs (can override)
export MOLECULE_IMAGE="${MOLECULE_IMAGE:-nixos/nix:2.21.5}"

# Set up environment
export PATH="$HOME/.local/share/pipx/venvs/molecule/bin:$HOME/.local/bin:$PATH"
# Resolve repository root to avoid '.' resolving inside role directories
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
export ANSIBLE_COLLECTIONS_PATH="$REPO_ROOT:$HOME/.ansible/collections:/usr/share/ansible/collections"

# Track overall success
OVERALL_SUCCESS=true

# Process each changed role
for role_path in $CHANGED_ROLES; do
    role_name=$(basename "$role_path")
    
    # Check if the role has a Molecule configuration
    if [ ! -f "$role_path/molecule/default/molecule.yml" ]; then
        echo -e "${YELLOW}⚠️  Skipping $role_name (no Molecule configuration)${NC}"
        continue
    fi
    
    echo -e "${YELLOW}📋 Checking $role_name...${NC}"
    
    # Run Molecule syntax check
    if (cd "$role_path" && molecule syntax); then
        echo -e "${GREEN}✅ $role_name syntax check passed${NC}"
    else
        echo -e "${RED}❌ $role_name syntax check failed${NC}"
        OVERALL_SUCCESS=false
    fi
done

# Final result
if [ "$OVERALL_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 All Molecule checks passed!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some Molecule checks failed. Please fix the issues before committing.${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "   - Run 'yamisskey-provision test <role-name> syntax' to debug specific issues"
    echo "   - Check your YAML syntax and Ansible task definitions"
    echo "   - Ensure all required variables are defined in defaults/main.yml"
    exit 1
fi
