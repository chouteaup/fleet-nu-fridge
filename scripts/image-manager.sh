#!/bin/bash
# Image Manager - Gestion images tenant
# Héritage du système Fleet Core avec adaptations tenant

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[ImageMgr] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[ImageMgr] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[ImageMgr] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[ImageMgr] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Tenant Image Manager"
    echo ""
    echo "Usage: $0 ACTION CONFIG_FILE MODULE"
    echo ""
    echo "Actions:"
    echo "  build  - Build tenant image with Fleet Core base"
    echo "  run    - Run tenant container"
    echo "  push   - Push tenant image to ACR"
    echo "  pull   - Pull tenant image from ACR"
    echo ""
    echo "Example:"
    echo "  $0 build config/fridge-dev.json Simulator"
}

# Load tenant configuration
load_tenant_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    # Extract tenant information
    TENANT=$(jq -r '.project.tenant' "$config_file")
    PROJECT=$(jq -r '.project.project' "$config_file")
    ENVIRONMENT=$(jq -r '.project.environment' "$config_file")
    REGISTRY=$(jq -r '.tenant_metadata.registry' "$config_file")

    print_info "Loaded configuration: $TENANT/$PROJECT ($ENVIRONMENT)"
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

    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"
    local base_image="${REGISTRY}/fleet-core/frontend:${ENVIRONMENT}-amd64"

    print_info "Building tenant image: $image_name"
    print_info "Using base image: $base_image"

    cd "$module_dir"
    docker build \
        --build-arg BASE_IMAGE="$base_image" \
        -t "$image_name" \
        .

    print_success "Image built successfully: $image_name"
}

# Run tenant container
run_container() {
    local module="$1"
    local image_name="${REGISTRY}/fleet-tenant/${TENANT,,}-${module,,}:${ENVIRONMENT}-amd64"
    local container_name="fleet-${TENANT,,}-${module,,}-dev"

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

    print_info "Starting container: $container_name"
    docker run -d \
        --name "$container_name" \
        -p 5174:5174 \
        -e VITE_TENANT="$TENANT" \
        -e VITE_TENANT_NAME="$TENANT $PROJECT" \
        -e VITE_BACKEND_URL="http://localhost:3001" \
        -e VITE_MQTT_URL="ws://localhost:9001" \
        "$image_name"

    print_success "Container started: $container_name"
    print_info "Available at: http://localhost:5174"
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
    load_tenant_config "$config_file"

    case "$action" in
        "build")
            build_image "$module"
            ;;
        "run")
            run_container "$module"
            ;;
        "push")
            print_info "Push functionality not implemented yet"
            ;;
        "pull")
            print_info "Pull functionality not implemented yet"
            ;;
        *)
            print_error "Unknown action: $action"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"