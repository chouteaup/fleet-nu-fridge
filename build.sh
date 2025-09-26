#!/bin/bash
set -e

# NU Fridge SmartKiosk - Build Script
# Usage: ./build.sh [--push] [--tag=<tag>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Parse arguments
PUSH=false
TAG="latest"

for arg in "$@"; do
    case $arg in
        --push)
            PUSH=true
            shift
            ;;
        --tag=*)
            TAG="${arg#*=}"
            shift
            ;;
        *)
            echo "Usage: $0 [--push] [--tag=<tag>]"
            exit 1
            ;;
    esac
done

log "🏗️  Building NU Fridge SmartKiosk images (tag: $TAG)"

# Get tenant info from package.json
TENANT_NAME=$(cat package.json | grep '"name"' | cut -d'"' -f4)
TENANT_VERSION=$(cat package.json | grep '"version"' | cut -d'"' -f4)

log "Building $TENANT_NAME:$TAG (version $TENANT_VERSION)"

# Build all images
log "Building backend image..."
docker build -f Dockerfile.backend -t "$TENANT_NAME-backend:$TAG" .
success "Backend image built"

log "Building frontend image..."
docker build -f Dockerfile.frontend -t "$TENANT_NAME-frontend:$TAG" .
success "Frontend image built"

log "Building nginx image..."
docker build -f Dockerfile.nginx -t "$TENANT_NAME-nginx:$TAG" .
success "Nginx image built"

# Tag with version if different from latest
if [[ "$TAG" != "latest" ]]; then
    docker tag "$TENANT_NAME-backend:$TAG" "$TENANT_NAME-backend:latest"
    docker tag "$TENANT_NAME-frontend:$TAG" "$TENANT_NAME-frontend:latest"
    docker tag "$TENANT_NAME-nginx:$TAG" "$TENANT_NAME-nginx:latest"
    success "Images tagged as latest"
fi

# Push if requested
if [[ "$PUSH" == true ]]; then
    log "Pushing images to registry..."
    # Note: Configure your registry here
    # docker push "$TENANT_NAME-backend:$TAG"
    # docker push "$TENANT_NAME-frontend:$TAG"
    # docker push "$TENANT_NAME-nginx:$TAG"
    echo "Push functionality not configured yet"
fi

log "📊 Built images:"
docker images | grep "$TENANT_NAME" | head -10

success "Build complete!"
echo
log "🚀 To test: docker-compose -f docker-compose.prod.yml up -d"
log "📊 To monitor: ./monitor.sh"