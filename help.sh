#!/bin/bash

# NU Fridge SmartKiosk - Help Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 NU Fridge SmartKiosk - Available Commands${NC}"
echo
echo -e "${YELLOW}Development:${NC}"
echo -e "  ${GREEN}./setup.sh dev${NC}      Start development environment with hot reload"
echo -e "  ${GREEN}./monitor.sh${NC}        Show system status and health checks"
echo -e "  ${GREEN}./monitor.sh --watch${NC} Continuous monitoring (Ctrl+C to stop)"
echo -e "  ${GREEN}./stop.sh dev${NC}       Stop development environment"
echo
echo -e "${YELLOW}Production:${NC}"
echo -e "  ${GREEN}./build.sh${NC}          Build production images"
echo -e "  ${GREEN}./setup.sh prod${NC}     Start production environment"
echo -e "  ${GREEN}./stop.sh prod${NC}      Stop production environment"
echo
echo -e "${YELLOW}Utilities:${NC}"
echo -e "  ${GREEN}./test-workflow.sh${NC}  Run complete workflow test"
echo -e "  ${GREEN}./stop.sh all${NC}       Stop all environments"
echo -e "  ${GREEN}./help.sh${NC}           Show this help"
echo
echo -e "${YELLOW}Documentation:${NC}"
echo -e "  ${GREEN}AI_AGENT_GUIDE.md${NC}   Complete guide for AI agents"
echo -e "  ${GREEN}README.md${NC}           Project overview and getting started"
echo
echo -e "${YELLOW}Development URLs:${NC}"
echo -e "  Frontend (Hot Reload): ${GREEN}http://localhost:5173${NC}"
echo -e "  Backend API:          ${GREEN}http://localhost:3001${NC}"
echo -e "  Full Interface:       ${GREEN}http://localhost:8080${NC}"
echo -e "  MQTT Broker:          ${GREEN}mqtt://localhost:1883${NC}"
echo
echo -e "${YELLOW}Quick Start:${NC}"
echo -e "  ${GREEN}1.${NC} az login"
echo -e "  ${GREEN}2.${NC} az acr login --name acrfleetcoredev"
echo -e "  ${GREEN}3.${NC} ./setup.sh dev"
echo -e "  ${GREEN}4.${NC} ./monitor.sh"
echo -e "  ${GREEN}5.${NC} Edit src/Dashboard.jsx"
echo -e "  ${GREEN}6.${NC} See changes on http://localhost:5173"
echo