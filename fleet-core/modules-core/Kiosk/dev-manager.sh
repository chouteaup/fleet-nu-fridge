#!/bin/bash
# Kiosk Module - Development Manager
# Responsabilité locale pour le module Kiosk

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Kiosk] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Kiosk] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Kiosk] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Kiosk] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Kiosk Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Kiosk in development mode"

    # Check if package.json exists
    if [[ -f "package.json" ]]; then
        # Node.js/React Kiosk
        print_info "Detected Node.js Kiosk application"

        # Install dependencies if node_modules doesn't exist
        if [[ ! -d "node_modules" ]]; then
            print_info "Installing npm dependencies..."
            if npm install --prefer-offline --no-audit; then
                print_success "Dependencies installed"
            else
                print_error "Failed to install dependencies"
                exit 1
            fi
        fi

        # Check for dev script
        if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
            print_info "Starting development server..."
            print_success "Kiosk will be available at: http://localhost:8080"
            exec npm run dev
        else
            print_warning "No 'dev' script found, trying 'start'"
            if jq -e '.scripts.start' package.json >/dev/null 2>&1; then
                exec npm run start
            else
                print_error "No 'dev' or 'start' script found in package.json"
                exit 1
            fi
        fi

    elif [[ -f "Dockerfile" ]]; then
        # Docker-based Kiosk
        print_info "Detected Docker-based Kiosk application"

        local image_name="fleet-kiosk-dev"
        local container_name="fleet-kiosk-dev"

        # Stop existing container
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true

        # Build and run
        if docker build -t "$image_name" .; then
            print_success "Kiosk image built"

            if docker run -d --name "$container_name" -p 8080:8080 "$image_name"; then
                print_success "Kiosk container started"
                print_success "Kiosk available at: http://localhost:8080"
            else
                print_error "Failed to start Kiosk container"
                exit 1
            fi
        else
            print_error "Failed to build Kiosk image"
            exit 1
        fi

    else
        print_error "No package.json or Dockerfile found in $(pwd)"
        print_info "Kiosk module needs either Node.js setup or Docker setup"
        exit 1
    fi
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Kiosk in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Kiosk
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