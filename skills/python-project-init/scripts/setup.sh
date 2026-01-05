#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    print_error "UV is not installed. Please install UV first: https://github.com/astral-sh/uv"
    exit 1
fi

print_info "Starting Python project initialization..."

# Step 1: Create virtual environment with Python 3.12
print_info "Creating virtual environment with Python 3.12..."
uv venv --python 3.12
print_success "Virtual environment created at .venv/"

# Step 2: Create .vscode directory if it doesn't exist
if [ ! -d ".vscode" ]; then
    mkdir .vscode
    print_success "Created .vscode/ directory"
fi

# Step 3: Copy configuration files (if they don't already exist)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(dirname "$SCRIPT_DIR")/assets"

if [ ! -f ".vscode/settings.json" ]; then
    cp "$ASSETS_DIR/vscode_settings.json.template" ".vscode/settings.json"
    print_success "Created .vscode/settings.json"
else
    print_info ".vscode/settings.json already exists, skipping..."
fi

if [ ! -f ".pre-commit-config.yaml" ]; then
    cp "$ASSETS_DIR/pre-commit-config.yaml.template" ".pre-commit-config.yaml"
    print_success "Created .pre-commit-config.yaml"
else
    print_info ".pre-commit-config.yaml already exists, skipping..."
fi

# Step 4: Install dependencies (if pyproject.toml exists)
if [ -f "pyproject.toml" ]; then
    print_info "Installing dependencies..."
    uv sync --extra dev
    print_success "Dependencies installed"

    # Step 5: Install pre-commit hooks
    print_info "Installing pre-commit hooks..."
    uv run pre-commit install
    print_success "Pre-commit hooks installed"
else
    print_info "pyproject.toml not found. Skipping dependency installation."
    print_info "Create pyproject.toml manually or use the template in $ASSETS_DIR/pyproject.toml.template"
fi

print_success "Python project initialization complete!"
echo ""
print_info "Next steps:"
echo "  1. Activate virtual environment: source .venv/bin/activate"
echo "  2. Install VSCode Ruff extension: charliermarsh.ruff"
echo "  3. Start coding!"
