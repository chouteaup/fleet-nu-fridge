#!/bin/bash

# NU Fridge SmartKiosk - Stop Script
# Usage: ./stop.sh [dev|prod|all]

MODE=${1:-all}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

log "🛑 Stopping NU Fridge SmartKiosk ($MODE)"

case "$MODE" in
    "dev")
        docker-compose -f docker-compose.dev.yml down --remove-orphans
        success "Development environment stopped"
        ;;
    "prod")
        docker-compose -f docker-compose.prod.yml down --remove-orphans
        success "Production environment stopped"
        ;;
    "all"|*)
        docker-compose -f docker-compose.dev.yml down --remove-orphans 2>/dev/null || true
        docker-compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true
        success "All environments stopped"
        ;;
esac

# Cleanup SmartKiosk internal containers (Docker-in-Docker)
log "🧹 Cleaning up SmartKiosk internal containers..."

# Arrêter les conteneurs internes créés par l'orchestrateur
for container in nufridge-backend nufridge-frontend nufridge-nginx nufridge-chromium; do
    if docker ps -q -f name="$container" | grep -q .; then
        log "Stopping internal container: $container"
        docker stop "$container" >/dev/null 2>&1 || true
        docker rm "$container" >/dev/null 2>&1 || true
    fi
done

# Nettoyer les réseaux internes
for network in nufridge-internal; do
    if docker network ls -q -f name="$network" | grep -q .; then
        log "Removing internal network: $network"
        docker network rm "$network" >/dev/null 2>&1 || true
    fi
done

log "📊 Remaining NU Fridge containers:"
docker ps | grep -E "(nufridge|smartkiosk)" || echo "None"

log "📦 SmartKiosk volumes:"
docker volume ls | grep -E "(smartkiosk|nufridge)" || echo "None"

echo
log "💡 To completely reset:"
echo "  • Remove volumes: docker volume prune"
echo "  • Remove images: docker rmi \$(docker images | grep nufridge | awk '{print \$3}')"
echo "  • Clean all: docker system prune -a"