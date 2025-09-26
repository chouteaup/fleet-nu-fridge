#!/bin/bash
set -e

# NU Fridge SmartKiosk - Setup Script
# Usage: ./setup.sh [dev|prod|test]

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
    echo "  • DevContainer Frontend (Hot Reload): http://localhost:5173"
    echo "  • DevContainer Backend API: http://localhost:3001"
    echo "  • DevContainer Interface: http://localhost:8080"
    echo "  • SmartKiosk Orchestrateur: http://localhost:8081"
    echo "  • MQTT: mqtt://localhost:1883"
    echo
    log "📝 DevContainer:"
    echo "  • Open in VS Code: code ."
    echo "  • Accept 'Reopen in Container' for full development environment"
    echo
    log "🐳 SmartKiosk Orchestrateur (Docker-in-Docker):"
    echo "  • Héberge backend/frontend/nginx/chromium en interne"
    echo "  • Logs: ./logs/"
    echo "  • Health: http://localhost:8081/health"

elif [ "$MODE" = "prod" ]; then
    log "Building production images..."
    docker-compose -f docker-compose.prod.yml build

    log "Starting production environment..."
    docker-compose -f docker-compose.prod.yml up -d

    success "Production environment started!"
    echo
    log "🌐 Access URLs:"
    echo "  • SmartKiosk Interface: http://localhost:8080"
    echo "  • SmartKiosk HTTPS: https://localhost:8443"
    echo "  • MQTT: mqtt://localhost:1883"
    echo
    log "🐳 Architecture Production:"
    echo "  • Hub: Service MQTT externe (ACR)"
    echo "  • SmartKiosk: Orchestrateur avec backend/frontend/nginx/chromium internes (ACR)"
    echo "  • Logs: ./logs/"
    echo
    warn "⚠️  Production nécessite authentification ACR pour images Fleet Core"

elif [ "$MODE" = "test" ]; then
    log "Building test images (mock containers)..."
    docker-compose -f docker-compose.test.yml build

    log "Starting test environment..."
    docker-compose -f docker-compose.test.yml up -d

    success "Test environment started!"
    echo
    log "🌐 Access URLs:"
    echo "  • SmartKiosk Interface: http://localhost:8080"
    echo "  • Direct Backend (mock): http://localhost:3001"
    echo "  • MQTT: mqtt://localhost:1883"
    echo
    log "🧪 Architecture Test:"
    echo "  • Hub: MQTT local (eclipse-mosquitto)"
    echo "  • SmartKiosk: Orchestrateur avec conteneurs mock nginx/alpine"
    echo "  • Mode: Validation architecture Docker-in-Docker"
    echo "  • Logs: ./logs/"
fi

# Health check
log "Performing health checks..."
sleep 5

# Check services (nouvelle architecture 2-services)
if [ "$MODE" = "dev" ]; then
    services=("hub" "smartkiosk-dev" "devcontainer")
elif [ "$MODE" = "test" ]; then
    services=("hub-test" "smartkiosk-test")
else
    services=("hub" "smartkiosk")
fi

for service in "${services[@]}"; do
    if docker-compose -f docker-compose.$MODE.yml ps | grep -q "$service.*Up"; then
        success "$service is running"
    else
        if [[ "$service" == "devcontainer" ]]; then
            warn "$service might be optional in some dev setups"
        else
            error "$service failed to start"
        fi
    fi
done

# Vérification spécifique SmartKiosk orchestrateur
if [ "$MODE" = "prod" ]; then
    log "Checking SmartKiosk internal services..."
    sleep 10  # Attendre que l'orchestrateur démarre les services internes

    # Vérifier les logs de l'orchestrateur
    if docker logs nufridge-smartkiosk 2>/dev/null | grep -q "SmartKiosk orchestrateur prêt"; then
        success "SmartKiosk orchestrateur has started internal services"
    else
        warn "SmartKiosk orchestrateur may still be initializing internal services"
        log "Check logs: docker logs nufridge-smartkiosk"
    fi
fi

success "NU Fridge SmartKiosk setup complete!"
log "📊 Monitor with: ./monitor.sh"
log "🔧 Build production: ./build.sh"
log "🛑 Stop: ./stop.sh"