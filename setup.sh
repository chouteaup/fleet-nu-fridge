#!/bin/bash
set -e

# NU Fridge SmartKiosk - Setup Script
# Usage: ./setup.sh [dev|prod]

MODE=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

log "🚀 Setting up NU Fridge SmartKiosk ($MODE mode)"

# Check prerequisites
command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"

# Create logs directory
mkdir -p logs

# Stop any existing containers
log "Stopping existing containers..."
docker-compose -f docker-compose.$MODE.yml down --remove-orphans || true

# Pull/build images based on mode
if [ "$MODE" = "dev" ]; then
    log "Pulling SmartKiosk Core images from ACR..."
    docker-compose -f docker-compose.dev.yml pull || warn "Could not pull all images (ACR access required)"

    log "Starting development environment..."
    docker-compose -f docker-compose.dev.yml up -d

    success "Development environment started!"
    echo
    log "🌐 Access URLs:"
    echo "  • Frontend (Hot Reload): http://localhost:5173"
    echo "  • Backend API: http://localhost:3001"
    echo "  • Full Interface: http://localhost:8080"
    echo "  • MQTT: mqtt://localhost:1883"
    echo
    log "📝 DevContainer:"
    echo "  • Open in VS Code: code ."
    echo "  • Accept 'Reopen in Container' for full development environment"

elif [ "$MODE" = "prod" ]; then
    log "Building production images..."
    docker-compose -f docker-compose.prod.yml build

    log "Starting production environment..."
    docker-compose -f docker-compose.prod.yml up -d

    success "Production environment started!"
    echo
    log "🌐 Access URLs:"
    echo "  • Interface: http://localhost:8080"
    echo "  • API: http://localhost:3001"
    echo "  • MQTT: mqtt://localhost:1883"
fi

# Health check
log "Performing health checks..."
sleep 5

# Check services
for service in hub backend; do
    if docker-compose -f docker-compose.$MODE.yml ps | grep -q "$service.*Up"; then
        success "$service is running"
    else
        error "$service failed to start"
    fi
done

if [ "$MODE" = "dev" ]; then
    if docker-compose -f docker-compose.dev.yml ps | grep -q "frontend.*Up"; then
        success "frontend is running"
    else
        warn "frontend might need manual start in DevContainer"
    fi
fi

success "NU Fridge SmartKiosk setup complete!"
log "📊 Monitor with: ./monitor.sh"
log "🔧 Build production: ./build.sh"
log "🛑 Stop: ./stop.sh"