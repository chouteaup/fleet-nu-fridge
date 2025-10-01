#!/bin/bash
# Simulator Module - Development Manager with Fleet Core Inheritance
# Responsabilité locale pour le module Simulator avec héritage Frontend

set -euo pipefail

# Configuration tenant
TENANT="NU"
PROJECT="Fridge"
MODULE="Simulator"
BASE_MODULE="Frontend"

# Chemins
WORKSPACE_ROOT="/workspace"
FLEET_CORE_PATH="../../fleet-core"

# Configuration développement
VITE_PORT=5174
VITE_TENANT="NU"
VITE_TENANT_NAME="NU Fridge"
VITE_BACKEND_URL="http://localhost:3001"
VITE_MQTT_URL="ws://localhost:9001"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Simulator] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Simulator] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Simulator] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Simulator] ⚠️  $1${NC}"
}

# Ensure Fleet Core is available
ensure_core_available() {
    if [[ ! -d "$FLEET_CORE_PATH" ]]; then
        print_error "Fleet Core not found at $FLEET_CORE_PATH"
        print_info "Expected: $FLEET_CORE_PATH/modules-core/Frontend/dev-manager.sh"
        exit 1
    fi

    if [[ ! -f "$FLEET_CORE_PATH/modules-core/Frontend/dev-manager.sh" ]]; then
        print_error "Fleet Core Frontend dev-manager not found"
        print_info "Expected: $FLEET_CORE_PATH/modules-core/Frontend/dev-manager.sh"
        exit 1
    fi
}

# Setup tenant development environment
setup_tenant_dev_environment() {
    print_info "Setting up tenant development environment..."

    # Set environment variables
    export VITE_PORT="$VITE_PORT"
    export VITE_TENANT="$VITE_TENANT"
    export VITE_TENANT_NAME="$VITE_TENANT_NAME"
    export VITE_BACKEND_URL="$VITE_BACKEND_URL"
    export VITE_MQTT_URL="$VITE_MQTT_URL"

    print_success "Environment configured for $VITE_TENANT_NAME"
}

# Adapt for tenant specifics
adapt_for_tenant() {
    print_info "Adapting configuration for tenant..."

    # Create tenant-specific package.json if it doesn't exist
    if [[ ! -f "package.json" ]]; then
        print_info "Creating tenant package.json..."
        cat > package.json << EOF
{
  "name": "nu-fridge-simulator",
  "version": "1.0.0",
  "description": "NU Fridge Simulator - Tenant module for Fleet IoT Platform",
  "main": "src/App.jsx",
  "scripts": {
    "dev": "vite --port $VITE_PORT",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "lucide-react": "^0.263.1"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.4.0"
  },
  "tenant": {
    "name": "nu-fridge",
    "displayName": "$VITE_TENANT_NAME",
    "base_module": "$BASE_MODULE",
    "port": $VITE_PORT
  }
}
EOF
        print_success "Tenant package.json created"
    fi

    # Create vite.config.js if it doesn't exist
    if [[ ! -f "vite.config.js" ]]; then
        print_info "Creating Vite configuration..."
        cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: parseInt(process.env.VITE_PORT) || 5174,
    host: true
  },
  define: {
    'process.env.VITE_TENANT': JSON.stringify(process.env.VITE_TENANT),
    'process.env.VITE_TENANT_NAME': JSON.stringify(process.env.VITE_TENANT_NAME),
    'process.env.VITE_BACKEND_URL': JSON.stringify(process.env.VITE_BACKEND_URL),
    'process.env.VITE_MQTT_URL': JSON.stringify(process.env.VITE_MQTT_URL)
  }
})
EOF
        print_success "Vite configuration created"
    fi
}

# Call Fleet Core Frontend dev-manager
call_fleet_core_frontend() {
    local mode="$1"
    local config_file="$2"

    print_info "Calling Fleet Core Frontend dev-manager..."

    local fleet_frontend_manager="$FLEET_CORE_PATH/modules-core/Frontend/dev-manager.sh"

    if [[ ! -f "$fleet_frontend_manager" ]]; then
        print_error "Fleet Core Frontend dev-manager not found: $fleet_frontend_manager"
        exit 1
    fi

    # Set environment for tenant
    export VITE_PORT="$VITE_PORT"
    export VITE_TENANT="$VITE_TENANT"
    export VITE_TENANT_NAME="$VITE_TENANT_NAME"
    export VITE_BACKEND_URL="$VITE_BACKEND_URL"
    export VITE_MQTT_URL="$VITE_MQTT_URL"

    # Execute Fleet Core Frontend dev-manager
    exec "$fleet_frontend_manager" "$mode" "$config_file"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Simulator in development mode"

    # Setup sequence
    ensure_core_available
    setup_tenant_dev_environment
    adapt_for_tenant

    print_success "Simulator setup completed, delegating to Fleet Core Frontend..."

    # Call Fleet Core Frontend dev-manager with tenant environment
    call_fleet_core_frontend "dev" "$config_file"
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Simulator in run mode (ACR image)"

    # Delegate to tenant image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager for tenant
    "$image_manager" run "$config_file" Simulator
}

# Usage
usage() {
    echo "Simulator Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (hot-reload)"
    echo "  run  - Launch from ACR image"
    echo ""
    echo "Example:"
    echo "  $0 dev ../../config/fridge-dev.json"
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