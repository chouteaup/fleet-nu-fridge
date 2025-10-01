#!/bin/bash
# NU Fridge - Tenant Development Manager
# Point d'entrée principal pour tous les modules tenant
# Usage: ./dev-manager.sh fleetcore-dev dev:Simulator run:Backend run:Hub

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[NU Fridge] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[NU Fridge] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[NU Fridge] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[NU Fridge] ⚠️  $1${NC}"
}

# Configuration tenant
TENANT="NU"
PROJECT="Fridge"
FLEET_CORE_PATH="fleet-core"

# Usage
usage() {
    echo "NU Fridge - Tenant Development Manager"
    echo ""
    echo "Usage: $0 CONFIG_NAME [mode:module ...]"
    echo ""
    echo "Examples:"
    echo "  $0 fridge-dev dev:Simulator run:Backend run:Hub"
    echo "  $0 fridge-dev dev:Simulator"
    echo ""
    echo "Modes:"
    echo "  dev:Module  - Launch module in development mode (hot-reload)"
    echo "  run:Module  - Launch module from ACR image"
    echo ""
    echo "Available modules:"
    echo "  - Simulator  (tenant module)"
    echo "  - Frontend   (Fleet Core)"
    echo "  - Backend    (Fleet Core)"
    echo "  - Hub        (Fleet Core)"
}

# Validate configuration
validate_config() {
    local config_name="$1"
    local config_file="config/${config_name}.json"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        echo "Available configs:"
        ls -1 config/*.json 2>/dev/null | sed 's/config\///g' | sed 's/\.json//g' | sed 's/^/  /'
        exit 1
    fi

    echo "$config_file"
}

# Validate Fleet Core availability
ensure_fleet_core() {
    if [[ ! -d "$FLEET_CORE_PATH" ]]; then
        print_error "Fleet Core not found at $FLEET_CORE_PATH"
        print_info "Available Fleet Core methods:"
        echo "  1. Setup via script: ../fleet-core/setup.sh"
        echo "  2. Manual sync: rsync -av ../../modules-core/ ../fleet-core/modules-core/"
        exit 1
    fi
}

# Parse arguments
parse_arguments() {
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    CONFIG_NAME="$1"
    shift

    MODULES=()
    while [[ $# -gt 0 ]]; do
        if [[ "$1" =~ ^(dev|run): ]]; then
            MODULES+=("$1")
        else
            print_error "Invalid module specification: $1"
            print_info "Use format: mode:Module (e.g., dev:Simulator, run:Backend)"
            exit 1
        fi
        shift
    done

    if [[ ${#MODULES[@]} -eq 0 ]]; then
        print_error "No modules specified"
        usage
        exit 1
    fi
}

# Launch tenant module
launch_tenant_module() {
    local mode="$1"
    local module="$2"
    local config_file="$3"

    local module_dir="modules/$module"

    print_info "Launching tenant module $module in $mode mode..."

    if [[ ! -d "$module_dir" ]]; then
        print_error "Tenant module directory not found: $module_dir"
        return 1
    fi

    local module_manager="$module_dir/dev-manager.sh"

    if [[ ! -f "$module_manager" ]]; then
        print_error "Module dev-manager not found: $module_manager"
        return 1
    fi

    # Convert config path to absolute path
    local absolute_config_file="$(realpath "$config_file")"

    # Execute module manager in background
    (
        cd "$module_dir"
        ./dev-manager.sh "$mode" "$absolute_config_file"
    ) &

    local module_pid=$!
    print_success "Tenant module $module started (PID: $module_pid)"

    echo "$module_pid:$module:$mode:tenant" >> "/tmp/nu-fridge-dev-manager.pids"
}

# Launch Fleet Core module
launch_fleet_core_module() {
    local mode="$1"
    local module="$2"
    local config_file="$3"

    print_info "Launching Fleet Core module $module in $mode mode..."

    local fleet_manager="$FLEET_CORE_PATH/modules-core/$module/dev-manager.sh"

    if [[ ! -f "$fleet_manager" ]]; then
        print_error "Fleet Core module dev-manager not found: $fleet_manager"
        return 1
    fi

    # Convert config path to absolute path
    local absolute_config_file="$(realpath "$config_file")"

    # Execute Fleet Core module manager in background
    (
        cd "$FLEET_CORE_PATH/modules-core/$module"
        ./dev-manager.sh "$mode" "$absolute_config_file"
    ) &

    local module_pid=$!
    print_success "Fleet Core module $module started (PID: $module_pid)"

    echo "$module_pid:$module:$mode:fleet-core" >> "/tmp/nu-fridge-dev-manager.pids"
}

# Launch module (tenant or Fleet Core)
launch_module() {
    local mode="$1"
    local module="$2"
    local config_file="$3"

    # Check if tenant module exists
    if [[ -d "modules/$module" ]]; then
        launch_tenant_module "$mode" "$module" "$config_file"
    elif [[ -d "$FLEET_CORE_PATH/modules-core/$module" ]]; then
        launch_fleet_core_module "$mode" "$module" "$config_file"
    else
        print_error "Module not found: $module"
        print_info "Available tenant modules:"
        ls -1 modules/ 2>/dev/null | sed 's/^/  /' || echo "  (none)"
        print_info "Available Fleet Core modules:"
        ls -1 "$FLEET_CORE_PATH/modules-core/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
        return 1
    fi
}

# Monitor running modules
monitor_modules() {
    local check_interval=5

    print_info "Monitoring modules every ${check_interval}s..."
    print_info "Press Ctrl+C to stop all modules"

    while true; do
        if [[ -f "/tmp/nu-fridge-dev-manager.pids" ]]; then
            local failed_modules=()

            while IFS=':' read -r pid module mode source; do
                if [[ -n "$pid" ]]; then
                    if ! kill -0 "$pid" 2>/dev/null; then
                        failed_modules+=("$module ($mode mode, $source)")
                    fi
                fi
            done < "/tmp/nu-fridge-dev-manager.pids"

            # Report failed modules
            if [[ ${#failed_modules[@]} -gt 0 ]]; then
                print_warning "Failed modules detected:"
                for failed in "${failed_modules[@]}"; do
                    print_error "  - $failed has stopped"
                done
            fi
        fi

        sleep "$check_interval"
    done
}

# Cleanup function
cleanup() {
    print_info "Stopping all NU Fridge modules..."

    if [[ -f "/tmp/nu-fridge-dev-manager.pids" ]]; then
        while IFS=':' read -r pid module mode source; do
            if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                print_info "Stopping $module ($source)..."
                kill "$pid" 2>/dev/null || true
            fi
        done < "/tmp/nu-fridge-dev-manager.pids"
        rm -f "/tmp/nu-fridge-dev-manager.pids"
    fi

    print_success "All NU Fridge modules stopped"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    echo "🚀 NU Fridge - Tenant Development Manager"
    echo "=========================================="

    # Parse arguments
    parse_arguments "$@"

    # Validate configuration and Fleet Core
    CONFIG_FILE=$(validate_config "$CONFIG_NAME")
    ensure_fleet_core

    print_success "Configuration loaded: $CONFIG_FILE"
    print_success "Fleet Core available: $FLEET_CORE_PATH"

    # Initialize PID tracking
    rm -f "/tmp/nu-fridge-dev-manager.pids"
    touch "/tmp/nu-fridge-dev-manager.pids"

    # Launch modules
    print_info "Launching ${#MODULES[@]} modules..."

    for module_spec in "${MODULES[@]}"; do
        IFS=':' read -r mode module <<< "$module_spec"

        launch_module "$mode" "$module" "$CONFIG_FILE"

        # Brief pause between launches
        sleep 1
    done

    print_success "All modules launched successfully!"

    # Monitor processes and wait for user interrupt
    monitor_modules
}

# Execute main function
main "$@"