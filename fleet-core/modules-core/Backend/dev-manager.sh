#!/bin/bash
# Backend Module - Development Manager
# Responsabilité locale pour le module Backend

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Backend] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Backend] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Backend] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Backend] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Backend Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (nodemon)"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Backend in development mode"

    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_error "package.json not found in $(pwd)"
        exit 1
    fi

    # Install dependencies if node_modules doesn't exist
    if [[ ! -d "node_modules" ]]; then
        print_info "Installing npm dependencies (including dev)..."
        if npm install --prefer-offline --no-audit; then
            print_success "Dependencies installed"
        else
            print_error "Failed to install dependencies"
            exit 1
        fi
    else
        # Check if dev dependencies are installed (nodemon needed for dev mode)
        if [[ ! -d "node_modules/nodemon" ]]; then
            print_info "Installing dev dependencies..."
            if npm install --prefer-offline --no-audit; then
                print_success "Dev dependencies installed"
            else
                print_error "Failed to install dev dependencies"
                exit 1
            fi
        fi
    fi

    # Check if dev script exists, fallback to start
    local dev_script="dev"
    if ! jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
        if jq -e '.scripts.start' package.json >/dev/null 2>&1; then
            dev_script="start"
            print_warning "No 'dev' script found, using 'start' script"
        else
            print_error "No 'dev' or 'start' script found in package.json"
            print_info "Available scripts:"
            jq -r '.scripts | keys[]' package.json 2>/dev/null | sed 's/^/  /'
            exit 1
        fi
    fi

    # Start development server
    print_info "Starting development server..."
    print_success "Backend API will be available at: http://localhost:3001"

    # Execute npm script
    exec npm run "$dev_script"
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Backend in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Backend
}

# Main execution
main() {
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    local mode="$1"
    local config_file="$2"

    # Validate config file
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    case "$mode" in
        "dev")
            dev_mode "$config_file"
            ;;
        "run")
            run_mode "$config_file"
            ;;
        *)
            print_error "Unknown mode: $mode"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"