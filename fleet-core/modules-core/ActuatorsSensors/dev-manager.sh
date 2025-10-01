#!/bin/bash
# ActuatorsSensors Module - Development Manager
# Responsabilité locale pour le module .NET ActuatorsSensors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[ActuatorsSensors] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[ActuatorsSensors] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[ActuatorsSensors] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[ActuatorsSensors] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "ActuatorsSensors Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (dotnet run)"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting ActuatorsSensors in development mode"

    # Find .csproj file
    local csproj_file=$(find . -name "*.csproj" -type f | head -1)

    if [[ -z "$csproj_file" ]]; then
        print_error "No .csproj file found in $(pwd)"
        exit 1
    fi

    print_info "Found project file: $csproj_file"

    # Check if dotnet is available
    if ! command -v dotnet &> /dev/null; then
        print_error "dotnet CLI not found. Please install .NET SDK."
        exit 1
    fi

    # Restore dependencies
    print_info "Restoring NuGet packages..."
    if dotnet restore "$csproj_file"; then
        print_success "Packages restored successfully"
    else
        print_warning "Package restore failed, continuing..."
    fi

    # Build project
    print_info "Building project..."
    if dotnet build "$csproj_file" --configuration Debug; then
        print_success "Build successful"
    else
        print_error "Build failed"
        exit 1
    fi

    # Run project
    print_info "Starting ActuatorsSensors module..."
    print_success "ActuatorsSensors module running in development mode"

    # Execute dotnet run
    exec dotnet run --project "$csproj_file" --configuration Debug
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting ActuatorsSensors in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" ActuatorsSensors
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