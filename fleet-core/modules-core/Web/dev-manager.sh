#!/bin/bash
# Web Module - Development Manager
# Responsabilité locale pour le module Nginx Web/Proxy

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Web] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Web] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Web] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Web] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Web Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (Docker build + run)"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Web (Nginx) module in development mode"

    # Check if nginx configuration exists
    if [[ ! -f "nginx.conf" ]] && [[ ! -f "nginx/nginx.conf" ]] && [[ ! -f "Dockerfile" ]]; then
        print_warning "No Nginx configuration found, creating minimal setup..."
        create_nginx_dev_setup
    fi

    # Web module uses Docker since it's Nginx-based
    local image_name="fleet-web-dev"
    local container_name="fleet-web-dev"

    # Stop existing container
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true

    # Build Nginx image for development (allows config editing)
    print_info "Building Nginx image for development..."
    if docker build -t "$image_name" .; then
        print_success "Nginx Web image built successfully"
    else
        print_error "Failed to build Web image"
        exit 1
    fi

    # Run container with development ports
    print_info "Starting Nginx Web proxy..."
    if docker run -d --name "$container_name" \
        -p 80:80 \
        -p 443:443 \
        "$image_name"; then
        print_success "Nginx Web proxy started"
        print_info "Available on:"
        print_info "  - HTTP: http://localhost (port 80)"
        print_info "  - HTTPS: https://localhost (port 443, if SSL configured)"
        print_info ""
        print_info "To edit configuration:"
        print_info "  1. Modify nginx.conf or Dockerfile"
        print_info "  2. Rebuild: docker build -t $image_name ."
        print_info "  3. Restart: docker restart $container_name"
    else
        print_error "Failed to start Nginx container"
        exit 1
    fi

    # Show container logs
    print_info "Nginx logs (Ctrl+C to stop):"
    docker logs -f "$container_name"
}

# Create minimal Nginx development setup if missing
create_nginx_dev_setup() {
    print_info "Creating minimal Nginx development setup..."

    # Create basic nginx.conf if missing
    if [[ ! -f "nginx.conf" ]]; then
        cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    upstream frontend {
        server host.docker.internal:5173;  # Vite dev server
    }

    upstream backend {
        server host.docker.internal:3001;  # Node.js API
    }

    server {
        listen 80;
        server_name localhost;

        # Frontend routes
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket support for Vite HMR
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # Backend API routes
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }
    }
}
EOF
        print_success "Basic nginx.conf created"
    fi

    # Create Dockerfile if missing
    if [[ ! -f "Dockerfile" ]]; then
        cat > Dockerfile << 'EOF'
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create nginx user following Fleet conventions
RUN addgroup -g 1001 fleetcore && \
    adduser -D -u 1001 -G fleetcore fleetcore

# Set permissions
RUN chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
EOF
        print_success "Basic Dockerfile created"
    fi
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Web in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Web
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