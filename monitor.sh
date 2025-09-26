#!/bin/bash

# NU Fridge SmartKiosk - Monitoring Script
# Real-time monitoring for AI agents and humans

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_status() {
    echo -e "${BLUE}=== NU Fridge SmartKiosk Status ===${NC}"
    echo

    # Container status
    echo -e "${YELLOW}📦 Container Status:${NC}"
    docker-compose -f docker-compose.dev.yml ps 2>/dev/null || docker-compose -f docker-compose.prod.yml ps 2>/dev/null || echo "No containers running"
    echo

    # Health checks
    echo -e "${YELLOW}🏥 Health Checks:${NC}"

    # Backend API health
    if curl -sf http://localhost:3001/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ UP${NC}"
    else
        echo -e "  Backend API: ${RED}❌ DOWN${NC}"
    fi

    # MQTT health
    if nc -z localhost 1883 2>/dev/null; then
        echo -e "  MQTT Broker: ${GREEN}✅ UP${NC} (port 1883)"
    else
        echo -e "  MQTT Broker: ${RED}❌ DOWN${NC}"
    fi

    # Frontend health (dev mode)
    if nc -z localhost 5173 2>/dev/null; then
        echo -e "  Frontend Dev: ${GREEN}✅ UP${NC} (port 5173)"
    else
        echo -e "  Frontend Dev: ${YELLOW}⚠️  DOWN${NC} (may be normal in prod)"
    fi

    # Nginx health
    if nc -z localhost 8080 2>/dev/null; then
        echo -e "  Nginx Proxy: ${GREEN}✅ UP${NC} (port 8080)"
    else
        echo -e "  Nginx Proxy: ${RED}❌ DOWN${NC}"
    fi

    echo

    # Recent logs
    echo -e "${YELLOW}📋 Recent Backend Logs:${NC}"
    docker-compose logs --tail=5 backend 2>/dev/null || echo "Backend logs not available"
    echo

    # Resource usage
    echo -e "${YELLOW}💻 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Docker stats not available"
    echo

    # URLs
    echo -e "${YELLOW}🌐 Access URLs:${NC}"
    echo "  • Frontend (Dev): http://localhost:5173"
    echo "  • Backend API: http://localhost:3001"
    echo "  • Full Interface: http://localhost:8080"
    echo "  • MQTT: mqtt://localhost:1883"
    echo

    # API endpoints for AI agents
    echo -e "${YELLOW}🤖 AI Agent API Endpoints:${NC}"
    echo "  • Health: curl http://localhost:3001/health"
    echo "  • MQTT Status: curl http://localhost:3001/api/mqtt/status"
    echo "  • Mock Devices: curl http://localhost:3001/api/mock/devices"
    echo "  • Send Command: curl -X POST http://localhost:3001/api/mqtt/send -d '{\"topic\":\"test\",\"message\":\"hello\"}' -H 'Content-Type: application/json'"
    echo
}

# Continuous monitoring mode
if [[ "$1" == "--watch" ]]; then
    echo "🔍 Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        show_status
        sleep 5
    done
else
    show_status
fi