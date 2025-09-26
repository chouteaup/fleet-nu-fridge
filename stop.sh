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

log "📊 Remaining containers:"
docker ps | grep -E "(nufridge|smartkiosk)" || echo "None"