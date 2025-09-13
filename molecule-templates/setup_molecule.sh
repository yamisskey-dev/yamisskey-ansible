#!/bin/bash

# Molecule setup script for yamisskey ansible collections
# This script adds molecule testing to all roles that don't already have it

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to setup molecule for a role
setup_molecule_for_role() {
    local role_path="$1"
    local role_name="$2" 
    local collection_name="$3"
    
    echo "Setting up Molecule for role: $role_name"
    
    # Create molecule directory structure
    mkdir -p "$role_path/molecule/default"
    
    # Generate molecule.yml
    sed "s/\${ROLE_NAME}/$role_name/g" "$SCRIPT_DIR/molecule.yml.template" > "$role_path/molecule/default/molecule.yml"
    
    # Generate converge.yml
    sed -e "s/\${ROLE_NAME}/$role_name/g" -e "s/\${COLLECTION_NAME}/$collection_name/g" "$SCRIPT_DIR/converge.yml.template" > "$role_path/molecule/default/converge.yml"
    
    # Generate verify.yml
    sed -e "s/\${ROLE_NAME}/$role_name/g" -e "s/\${COLLECTION_NAME}/$collection_name/g" "$SCRIPT_DIR/verify.yml.template" > "$role_path/molecule/default/verify.yml"
    
    echo "✅ Molecule setup completed for $role_name"
}

# Process appliances collection
echo "Processing yamisskey.appliances collection..."
APPLIANCES_ROLES_DIR="$PROJECT_ROOT/ansible_collections/yamisskey/appliances/roles"

if [ -d "$APPLIANCES_ROLES_DIR" ]; then
    for role_dir in "$APPLIANCES_ROLES_DIR"/*; do
        if [ -d "$role_dir" ] && [ "$(basename "$role_dir")" != "README.md" ]; then
            role_name="$(basename "$role_dir")"
            
            # Skip if molecule already exists
            if [ ! -d "$role_dir/molecule" ]; then
                setup_molecule_for_role "$role_dir" "$role_name" "yamisskey.appliances"
            else
                echo "⏭️  Skipping $role_name (molecule already exists)"
            fi
        fi
    done
fi

# Process servers collection
echo "Processing yamisskey.servers collection..."
SERVERS_ROLES_DIR="$PROJECT_ROOT/ansible_collections/yamisskey/servers/roles"

if [ -d "$SERVERS_ROLES_DIR" ]; then
    for role_dir in "$SERVERS_ROLES_DIR"/*; do
        if [ -d "$role_dir" ] && [ "$(basename "$role_dir")" != "README.md" ]; then
            role_name="$(basename "$role_dir")"
            
            # Skip if molecule already exists
            if [ ! -d "$role_dir/molecule" ]; then
                setup_molecule_for_role "$role_dir" "$role_name" "yamisskey.servers"
            else
                echo "⏭️  Skipping $role_name (molecule already exists)"
            fi
        fi
    done
fi

echo "🎉 Molecule setup completed for all roles!"
echo ""
echo "Next steps:"
echo "1. Customize the molecule configurations for specific roles as needed"
echo "2. Run 'molecule test' in each role directory to verify the setup"
echo "3. Update converge.yml and verify.yml with role-specific tests"