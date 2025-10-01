#!/bin/bash
# Hub Module - Development Manager
# Responsabilité locale pour le module Hub (MQTT Broker)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Hub] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Hub] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Hub] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Hub] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Hub Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Build and run Hub locally (for Dockerfile editing)"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Hub in development mode"

    # Check if Dockerfile exists
    if [[ ! -f "Dockerfile" ]]; then
        print_error "Dockerfile not found in $(pwd)"
        exit 1
    fi

    local image_name="fleet-hub-dev"
    local container_name="fleet-hub-dev"

    # Stop and remove existing container
    print_info "Stopping existing container..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true

    # Build image
    print_info "Building Hub image..."
    if docker build -t "$image_name" .; then
        print_success "Hub image built successfully"
    else
        print_error "Failed to build Hub image"
        exit 1
    fi

    # Create data directories if they don't exist
    mkdir -p data logs

    # Run container
    print_info "Starting Hub container..."

    if docker run -d \
        --name "$container_name" \
        -p 1883:1883 \
        -p 9001:9001 \
        -v "$(pwd)/data:/mosquitto/data" \
        -v "$(pwd)/logs:/mosquitto/log" \
        "$image_name"; then

        print_success "Hub container started successfully"
        print_success "MQTT Broker available at: mqtt://localhost:1883"
        print_success "WebSocket available at: ws://localhost:9001"

        # Wait a bit and check if container is running
        sleep 2
        if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
            print_success "Hub is running and healthy"

            # Show logs briefly
            print_info "Container logs (last 10 lines):"
            docker logs --tail 10 "$container_name"
        else
            print_warning "Hub container may have issues. Check logs with: docker logs $container_name"
        fi
    else
        print_error "Failed to start Hub container"
        exit 1
    fi
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Hub in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Hub
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