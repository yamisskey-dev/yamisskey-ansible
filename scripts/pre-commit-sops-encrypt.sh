#!/bin/bash
# Pre-commit hook to encrypt secrets files with SOPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[SOPS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[SOPS WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[SOPS ERROR]${NC} $1"
}

# Check if age key file exists
AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    print_error "Age key file not found at: $AGE_KEY_FILE"
    print_error "Please generate age keys first:"
    print_error "  mkdir -p ~/.config/sops/age"
    print_error "  age-keygen -o ~/.config/sops/age/keys.txt"
    exit 1
fi

# Find all secrets files that need to be encrypted
secrets_files=()
while IFS= read -r -d '' file; do
    # Check if file is not already encrypted (doesn't contain sops metadata)
    if ! grep -q "sops:" "$file" 2>/dev/null; then
        secrets_files+=("$file")
    fi
done < <(find . -name "secrets.yml" -type f -not -path "*/.vendor/*" -print0)

if [ ${#secrets_files[@]} -eq 0 ]; then
    print_status "No unencrypted secrets files found."
    exit 0
fi

# Process each secrets file
for file in "${secrets_files[@]}"; do
    print_status "Encrypting: $file"

    # Create backup
    cp "$file" "${file}.backup"

    # Encrypt with sops
    if "$SOPS_CMD" --encrypt --in-place "$file"; then
        print_status "Successfully encrypted: $file"
        # Remove backup on success
        rm "${file}.backup"
    else
        print_error "Failed to encrypt: $file"
        # Restore backup on failure
        mv "${file}.backup" "$file"
        exit 1
    fi
done

print_status "All secrets files have been encrypted successfully!"
print_warning "Remember to add the age key file to .gitignore if not already done:"
print_warning "  echo 'age-key.txt' >> .gitignore"
print_warning "  echo '.config/sops/' >> .gitignore"
