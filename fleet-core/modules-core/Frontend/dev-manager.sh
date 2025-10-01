#!/bin/bash
# Frontend Module - Development Manager
# Responsabilité locale pour le module Frontend

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Frontend] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Frontend] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Frontend] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Frontend] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Frontend Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (hot-reload)"
    echo "  run  - Launch from ACR image"
}

# REUSABLE_FUNCTIONS_START
# Install dependencies with error handling
install_dependencies() {
    if [[ ! -d "node_modules" ]]; then
        print_info "Installing npm dependencies..."
        if npm install --prefer-offline --no-audit; then
            print_success "Dependencies installed"
        else
            print_error "Failed to install dependencies"
            exit 1
        fi
    fi
}

# Check if dev script exists in package.json
check_dev_script() {
    if ! jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
        print_error "No 'dev' script found in package.json"
        print_info "Available scripts:"
        jq -r '.scripts | keys[]' package.json 2>/dev/null | sed 's/^/  /'
        exit 1
    fi
}

# Start development server with configurable port
start_dev_server() {
    local port="${1:-5173}"
    print_info "Starting development server..."
    print_success "Frontend dev server will be available at: http://localhost:$port"

    # Execute npm run dev with optional port
    if [[ "$port" != "5173" ]]; then
        exec npm run dev -- --port "$port"
    else
        exec npm run dev
    fi
}
# REUSABLE_FUNCTIONS_END

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Frontend in development mode"

    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_error "package.json not found in $(pwd)"
        exit 1
    fi

    # Use reusable functions
    install_dependencies
    check_dev_script
    start_dev_server
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Frontend in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Frontend
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