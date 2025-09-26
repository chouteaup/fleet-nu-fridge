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

    # SmartKiosk Orchestrateur health
    if nc -z localhost 8080 2>/dev/null; then
        echo -e "  SmartKiosk Interface: ${GREEN}✅ UP${NC} (port 8080)"
    else
        echo -e "  SmartKiosk Interface: ${RED}❌ DOWN${NC}"
    fi

    # Backend API health (via orchestrateur ou devcontainer)
    backend_up=false
    if curl -sf http://localhost:3001/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ UP${NC} (direct/devcontainer)"
        backend_up=true
    elif curl -sf http://localhost:8080/api/health >/dev/null 2>&1; then
        echo -e "  Backend API: ${GREEN}✅ UP${NC} (via SmartKiosk)"
        backend_up=true
    else
        echo -e "  Backend API: ${RED}❌ DOWN${NC}"
    fi

    # MQTT health
    if nc -z localhost 1883 2>/dev/null; then
        echo -e "  MQTT Broker: ${GREEN}✅ UP${NC} (port 1883)"
    else
        echo -e "  MQTT Broker: ${RED}❌ DOWN${NC}"
    fi

    # Frontend health (dev mode direct)
    if nc -z localhost 5173 2>/dev/null; then
        echo -e "  Frontend Dev: ${GREEN}✅ UP${NC} (devcontainer hot-reload)"
    else
        echo -e "  Frontend Dev: ${YELLOW}⚠️  DOWN${NC} (using SmartKiosk build)"
    fi

    # SmartKiosk Dev (port alternatif)
    if nc -z localhost 8081 2>/dev/null; then
        echo -e "  SmartKiosk Dev: ${GREEN}✅ UP${NC} (port 8081)"
    else
        echo -e "  SmartKiosk Dev: ${YELLOW}⚠️  DOWN${NC} (dev mode only)"
    fi

    echo

    # Recent logs
    echo -e "${YELLOW}📋 Recent SmartKiosk Logs:${NC}"
    # Essayer logs orchestrateur prod
    if docker logs nufridge-smartkiosk --tail=5 2>/dev/null; then
        echo
    # Ou logs orchestrateur dev
    elif docker logs nufridge-smartkiosk-dev --tail=5 2>/dev/null; then
        echo
    # Fallback logs devcontainer backend
    elif docker-compose logs --tail=5 devcontainer 2>/dev/null; then
        echo
    else
        echo "SmartKiosk logs not available"
    fi
    echo

    # Resource usage
    echo -e "${YELLOW}💻 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Docker stats not available"
    echo

    # URLs (nouvelle architecture)
    echo -e "${YELLOW}🌐 Access URLs:${NC}"
    echo "  • 🎯 SmartKiosk Production: http://localhost:8080"
    echo "  • 🔧 SmartKiosk Development: http://localhost:8081"
    echo "  • ⚡ Frontend Hot-Reload: http://localhost:5173"
    echo "  • 🔌 Backend API Direct: http://localhost:3001"
    echo "  • 📡 MQTT Broker: mqtt://localhost:1883"
    echo

    # Architecture info
    echo -e "${YELLOW}🏗️  Architecture Info:${NC}"
    echo "  • Hub: Service MQTT externe (Fleet Core)"
    echo "  • SmartKiosk: Orchestrateur Docker-in-Docker"
    echo "    ├─ backend (interne)"
    echo "    ├─ frontend (interne)"
    echo "    ├─ nginx (interne)"
    echo "    └─ chromium (interne)"
    echo "  • DevContainer: Hot-reload pour développement"
    echo

    # API endpoints for AI agents
    echo -e "${YELLOW}🤖 AI Agent API Endpoints:${NC}"
    echo "  • SmartKiosk Health: curl http://localhost:8080/api/health"
    echo "  • Backend Direct: curl http://localhost:3001/health"
    echo "  • MQTT Status: curl http://localhost:8080/api/mqtt/status"
    echo "  • Mock Devices: curl http://localhost:8080/api/mock/devices"
    echo "  • Send Command: curl -X POST http://localhost:8080/api/mqtt/send -H 'Content-Type: application/json' -d '{\"topic\":\"test\",\"message\":\"hello\"}'"
    echo

    # SmartKiosk internal monitoring
    echo -e "${YELLOW}📊 SmartKiosk Internal Services:${NC}"
    if [ -f "./logs/health-status.json" ]; then
        echo "  • Health Status Available: ./logs/health-status.json"
        if command -v jq >/dev/null 2>&1; then
            jq -r '.services | to_entries[] | "    " + .key + ": " + .value.status' ./logs/health-status.json 2>/dev/null || echo "  • Health status file exists but not readable"
        else
            echo "  • Install jq to view detailed health status"
        fi
    else
        echo "  • Health status file not found (SmartKiosk may be starting)"
    fi
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