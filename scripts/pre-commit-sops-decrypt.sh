#!/bin/bash
# Pre-commit hook to decrypt secrets files with SOPS for linting

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

# Check if sops is installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOPS_CMD="$PROJECT_ROOT/.bin/sops"
if [ ! -f "$SOPS_CMD" ]; then
    print_error "SOPS is not found at $SOPS_CMD. Please install it first."
    exit 1
fi

# Check if age key file exists
AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    print_error "Age key file not found at: $AGE_KEY_FILE"
    exit 1
fi

# Find all encrypted secrets files
secrets_files=()
while IFS= read -r -d '' file; do
    # Check if file is encrypted (contains sops metadata)
    if grep -q "sops:" "$file" 2>/dev/null; then
        secrets_files+=("$file")
    fi
done < <(find . -name "secrets.yml" -type f -not -path "*/.vendor/*" -print0)

if [ ${#secrets_files[@]} -eq 0 ]; then
    print_status "No encrypted secrets files found."
    exit 0
fi

# Process each encrypted secrets file
for file in "${secrets_files[@]}"; do
    print_status "Decrypting for linting: $file"

    # Create temporary decrypted file
    temp_file="${file}.decrypted"

    # Decrypt with sops
    if "$SOPS_CMD" --decrypt "$file" > "$temp_file"; then
        print_status "Successfully decrypted: $file"
        # Replace original with decrypted version for linting
        mv "$temp_file" "$file"
    else
        print_error "Failed to decrypt: $file"
        # Clean up temp file on failure
        rm -f "$temp_file"
        exit 1
    fi
done

print_status "All secrets files have been decrypted for linting!"
