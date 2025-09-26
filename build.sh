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
TENANT_NAME=$(cat package.json | grep '"name"' | head -1 | cut -d'"' -f4)
TENANT_VERSION=$(cat package.json | grep '"version"' | head -1 | cut -d'"' -f4)

log "Building $TENANT_NAME:$TAG (version $TENANT_VERSION)"

# Build all component images (multi-image architecture)
log "Building Backend image..."
docker build -f Dockerfile.backend -t "$TENANT_NAME-backend:$TAG" .
success "Backend image built"

log "Building Frontend image..."
docker build -f Dockerfile.frontend -t "$TENANT_NAME-frontend:$TAG" .
success "Frontend image built"

log "Building Web server image..."
docker build -f Dockerfile.web -t "$TENANT_NAME-web:$TAG" .
success "Web server image built"

log "Building Kiosk display image..."
docker build -f Dockerfile.kiosk -t "$TENANT_NAME-kiosk:$TAG" .
success "Kiosk display image built"

log "Note: Multi-image architecture avec images Fleet Core étendues"

# Tag with version if different from latest
if [[ "$TAG" != "latest" ]]; then
    docker tag "$TENANT_NAME-backend:$TAG" "$TENANT_NAME-backend:latest"
    docker tag "$TENANT_NAME-frontend:$TAG" "$TENANT_NAME-frontend:latest"
    docker tag "$TENANT_NAME-web:$TAG" "$TENANT_NAME-web:latest"
    docker tag "$TENANT_NAME-kiosk:$TAG" "$TENANT_NAME-kiosk:latest"
    success "All images tagged as latest"
fi

# Push if requested
if [[ "$PUSH" == true ]]; then
    log "Pushing all component images to registry..."
    # Note: Configure your registry here
    # docker push "$TENANT_NAME-backend:$TAG"
    # docker push "$TENANT_NAME-frontend:$TAG"
    # docker push "$TENANT_NAME-web:$TAG"
    # docker push "$TENANT_NAME-kiosk:$TAG"
    echo "Push functionality not configured yet"
    echo "To push individually:"
    echo "  docker push $TENANT_NAME-backend:$TAG"
    echo "  docker push $TENANT_NAME-frontend:$TAG"
    echo "  docker push $TENANT_NAME-web:$TAG"
    echo "  docker push $TENANT_NAME-kiosk:$TAG"
fi

log "📊 Built images:"
docker images | grep "$TENANT_NAME" | head -10

log "🐳 Multi-Image Architecture:"
echo "  • $TENANT_NAME-backend:$TAG (API + MQTT bridge)"
echo "  • $TENANT_NAME-frontend:$TAG (React application)"
echo "  • $TENANT_NAME-web:$TAG (Nginx reverse proxy)"
echo "  • $TENANT_NAME-kiosk:$TAG (Chromium display)"
echo "  • Services séparés pour meilleure maintenabilité"

success "Build complete!"
echo
log "🚀 To test: docker-compose -f docker-compose.prod.yml up -d"
log "📊 To monitor: ./monitor.sh"