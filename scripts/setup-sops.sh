#!/bin/bash
# Setup script for SOPS encryption with age keys

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_status "Setting up SOPS encryption for yamisskey-provision..."

# Check if sops is installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOPS_CMD="$PROJECT_ROOT/.bin/sops"
if [ ! -f "$SOPS_CMD" ]; then
    print_error "SOPS is not found at $SOPS_CMD. Please install it first."
    exit 1
fi

# Check if age is installed
if ! command -v age &> /dev/null; then
    print_error "Age is not installed. Please install it first:"
    print_error "  - macOS: brew install age"
    print_error "  - Ubuntu/Debian: apt-get install age"
    print_error "  - Or download from: https://github.com/FiloSottile/age/releases"
    exit 1
fi

# Create age key directory
AGE_KEY_DIR="${HOME}/.config/sops/age"
mkdir -p "$AGE_KEY_DIR"

# Check if age key exists
AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    print_status "Generating age key..."
    age-keygen -o "$AGE_KEY_FILE"
    print_status "Age key generated at: $AGE_KEY_FILE"
else
    print_info "Using existing age key at: $AGE_KEY_FILE"
fi

# Extract public key
PUBLIC_KEY=$(grep -o 'age1[^"]*' "$AGE_KEY_FILE" | head -1)
print_info "Public key: $PUBLIC_KEY"

# Update .sops.yaml with the public key (only if needed)
print_status "Checking .sops.yaml configuration..."
if grep -q "age1j3d572hhlycq54vll6xk5cfdeezw09vr6px3rk6k725zayugwf7s04dvf3" .sops.yaml; then
    print_status "Updating .sops.yaml with current public key..."
    sed -i.bak "s/age1j3d572hhlycq54vll6xk5cfdeezw09vr6px3rk6k725zayugwf7s04dvf3/$PUBLIC_KEY/g" .sops.yaml
    rm .sops.yaml.bak
else
    print_info ".sops.yaml already configured with current public key"
fi

print_status "SOPS setup completed successfully!"
print_warning "IMPORTANT SECURITY NOTES:"
print_warning "1. Keep your age key file secure: $AGE_KEY_FILE"
print_warning "2. Never commit the age key file to Git"
print_warning "3. Back up your age key file securely"
print_warning "4. Share the public key with team members who need to encrypt files"
print_warning "5. The public key has been updated in .sops.yaml"

print_info "You can now encrypt secrets files with:"
print_info "  $SOPS_CMD --encrypt --in-place --age '$PUBLIC_KEY' path/to/secrets.yml"
print_info "And decrypt with:"
print_info "  $SOPS_CMD --decrypt --in-place --age '$PUBLIC_KEY' path/to/secrets.yml"
