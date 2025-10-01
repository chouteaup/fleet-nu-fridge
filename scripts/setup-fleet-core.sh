#!/bin/bash
# Setup Fleet Core - Clone/sync Fleet Core repository
# Exécuté automatiquement à postCreateCommand

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Setup] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Setup] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Setup] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Setup] ⚠️  $1${NC}"
}

# Configuration
FLEET_CORE_PATH="${FLEET_CORE_PATH:-/workspace/.fleet-core}"
FLEET_CORE_REPO="${FLEET_CORE_REPO:-https://github.com/fleet-org/fleet.git}"
FLEET_CORE_BRANCH="${FLEET_CORE_BRANCH:-main}"

main() {
    print_info "Setting up Fleet Core for tenant development..."

    # Check if Fleet Core already exists
    if [[ -d "$FLEET_CORE_PATH" ]]; then
        print_info "Fleet Core directory exists, updating..."
        cd "$FLEET_CORE_PATH"

        if [[ -d ".git" ]]; then
            git fetch origin "$FLEET_CORE_BRANCH"
            git reset --hard "origin/$FLEET_CORE_BRANCH"
            print_success "Fleet Core updated to latest $FLEET_CORE_BRANCH"
        else
            print_warning "Fleet Core directory exists but is not a git repository"
            print_info "Removing and re-cloning..."
            cd /workspace
            rm -rf "$FLEET_CORE_PATH"
            git clone -b "$FLEET_CORE_BRANCH" "$FLEET_CORE_REPO" "$FLEET_CORE_PATH"
            print_success "Fleet Core cloned fresh"
        fi
    else
        print_info "Cloning Fleet Core..."
        git clone -b "$FLEET_CORE_BRANCH" "$FLEET_CORE_REPO" "$FLEET_CORE_PATH"
        print_success "Fleet Core cloned successfully"
    fi

    # Copy templates if needed
    if [[ -f "$FLEET_CORE_PATH/config/fleet-templates.json" ]]; then
        if [[ ! -f "/workspace/config/fleet-templates.json" ]]; then
            print_info "Copying Fleet templates..."
            cp "$FLEET_CORE_PATH/config/fleet-templates.json" "/workspace/config/"
            print_success "Fleet templates copied"
        fi
    fi

    print_success "Fleet Core setup completed"
    print_info "Fleet Core available at: $FLEET_CORE_PATH"
}

# Execute main function
main "$@"