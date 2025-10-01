#!/bin/bash
# NU Fridge - Tenant Image Manager
# Gestion images tenant avec héritage Fleet Core

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[NU Image] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[NU Image] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[NU Image] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[NU Image] ⚠️  $1${NC}"
}

# Configuration
TENANT="NU"
PROJECT="Fridge"
FLEET_CORE_PATH="../fleet-core"

# Usage
usage() {
    echo "NU Fridge - Tenant Image Manager"
    echo ""
    echo "Usage: $0 ACTION CONFIG_FILE MODULE"
    echo ""
    echo "Actions:"
    echo "  build  - Build tenant image with Fleet Core base"
    echo "  run    - Run tenant container"
    echo "  push   - Push tenant image to ACR"
    echo "  pull   - Pull tenant image from ACR"
    echo ""
    echo "Examples:"
    echo "  $0 build config/fridge-dev.json Simulator"
    echo "  $0 run config/fridge-dev.json Simulator"
}

# Load configuration
load_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    # Extract configuration
    ENVIRONMENT=$(jq -r '.project.environment' "$config_file")
    REGISTRY=$(jq -r '.tenant_metadata.registry' "$config_file")

    print_info "Loaded configuration: $TENANT/$PROJECT ($ENVIRONMENT)"
    print_info "Registry: $REGISTRY"
}

# Build tenant image
build_image() {
    local module="$1"
    local module_dir="modules/$module"

    if [[ ! -d "$module_dir" ]]; then
        print_error "Module directory not found: $module_dir"
        exit 1
    fi

    if [[ ! -f "$module_dir/Dockerfile" ]]; then
        print_error "Dockerfile not found in $module_dir"
        exit 1
    fi

    # Determine base module from configuration or default
    local base_module="frontend"  # Default for Simulator
    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"
    local base_image="${REGISTRY}/fleet-core/${base_module}:${ENVIRONMENT}-amd64"

    print_info "Building tenant image: $image_name"
    print_info "Using base image: $base_image"

    cd "$module_dir"

    # Build with base image argument
    docker build \
        --build-arg BASE_IMAGE="$base_image" \
        -t "$image_name" \
        . || {
        print_error "Docker build failed"
        exit 1
    }

    print_success "Image built successfully: $image_name"
}

# Run tenant container
run_container() {
    local module="$1"
    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"
    local container_name="nu-fridge-${module,,}-dev"

    # Try to pull image first, build if not available
    if ! docker pull "$image_name" 2>/dev/null; then
        print_warning "Image not available in registry, building locally..."
        build_image "$module"
    fi

    # Stop existing container if running
    if docker ps -q --filter "name=$container_name" | grep -q .; then
        print_info "Stopping existing container: $container_name"
        docker stop "$container_name" >/dev/null 2>&1 || true
    fi

    # Remove existing container
    if docker ps -aq --filter "name=$container_name" | grep -q .; then
        print_info "Removing existing container: $container_name"
        docker rm "$container_name" >/dev/null 2>&1 || true
    fi

    # Determine port based on module
    local port
    case "$module" in
        "Simulator")
            port="5174:5174"
            ;;
        "Frontend")
            port="5173:5173"
            ;;
        *)
            port="8080:8080"  # Default
            ;;
    esac

    print_info "Starting container: $container_name"
    docker run -d \
        --name "$container_name" \
        -p "$port" \
        -e TENANT="$TENANT" \
        -e PROJECT="$PROJECT" \
        -e VITE_TENANT="$TENANT" \
        -e VITE_TENANT_NAME="$TENANT $PROJECT" \
        -e VITE_BACKEND_URL="http://localhost:3001" \
        -e VITE_MQTT_URL="ws://localhost:9001" \
        "$image_name"

    print_success "Container started: $container_name"

    # Extract port for display
    local display_port
    display_port=$(echo "$port" | cut -d':' -f1)
    print_info "Available at: http://localhost:$display_port"
}

# Push image to registry
push_image() {
    local module="$1"
    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"

    print_info "Pushing image: $image_name"

    # Check if image exists locally
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
        print_warning "Image not found locally, building first..."
        build_image "$module"
    fi

    # Push to registry
    docker push "$image_name" || {
        print_error "Failed to push image to registry"
        print_info "Make sure you're authenticated: az acr login --name $(echo "$REGISTRY" | cut -d'.' -f1)"
        exit 1
    }

    print_success "Image pushed successfully: $image_name"
}

# Pull image from registry
pull_image() {
    local module="$1"
    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"

    print_info "Pulling image: $image_name"

    if docker pull "$image_name"; then
        print_success "Image pulled successfully: $image_name"
    else
        print_error "Failed to pull image from registry"
        print_info "Available options:"
        echo "  1. Build locally: $0 build $CONFIG_FILE $module"
        echo "  2. Check registry auth: az acr login --name $(echo "$REGISTRY" | cut -d'.' -f1)"
        exit 1
    fi
}

# Delegate to Fleet Core image manager
delegate_to_fleet_core() {
    local action="$1"
    local config_file="$2"
    local module="$3"

    local fleet_image_manager="$FLEET_CORE_PATH/image-manager.sh"

    if [[ ! -f "$fleet_image_manager" ]]; then
        print_error "Fleet Core image manager not found: $fleet_image_manager"
        exit 1
    fi

    print_info "Delegating to Fleet Core image manager..."
    "$fleet_image_manager" "$action" "$config_file" "$module"
}

# Main execution
main() {
    if [[ $# -lt 3 ]]; then
        usage
        exit 1
    fi

    local action="$1"
    local config_file="$2"
    local module="$3"

    # Load configuration
    CONFIG_FILE="$config_file"
    load_config "$config_file"

    # Check if this is a tenant module or Fleet Core module
    if [[ -d "modules/$module" ]]; then
        # Tenant module - handle locally
        case "$action" in
            "build")
                build_image "$module"
                ;;
            "run")
                run_container "$module"
                ;;
            "push")
                push_image "$module"
                ;;
            "pull")
                pull_image "$module"
                ;;
            *)
                print_error "Unknown action: $action"
                usage
                exit 1
                ;;
        esac
    elif [[ -d "$FLEET_CORE_PATH/modules-core/$module" ]]; then
        # Fleet Core module - delegate
        delegate_to_fleet_core "$action" "$config_file" "$module"
    else
        print_error "Module not found: $module"
        print_info "Available tenant modules:"
        ls -1 modules/ 2>/dev/null | sed 's/^/  /' || echo "  (none)"
        print_info "Available Fleet Core modules:"
        ls -1 "$FLEET_CORE_PATH/modules-core/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
        exit 1
    fi
}

# Execute main function
main "$@"