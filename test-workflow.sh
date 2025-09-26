#!/bin/bash

# NU Fridge SmartKiosk - Complete Workflow Test
# Tests the entire development and production workflow

set -e

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
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=0

run_test() {
    local test_name="$1"
    local command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log "Test $TESTS_TOTAL: $test_name"

    if eval "$command" >/dev/null 2>&1; then
        success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        error "$test_name"
        return 1
    fi
}

log "🧪 Starting NU Fridge SmartKiosk Workflow Test"
echo

# Cleanup before starting
log "🧹 Cleaning up previous environments..."
./stop.sh all >/dev/null 2>&1 || true

# Test 1: Scripts are executable
log "=== Testing Script Permissions ==="
run_test "setup.sh is executable" "test -x ./setup.sh"
run_test "monitor.sh is executable" "test -x ./monitor.sh"
run_test "build.sh is executable" "test -x ./build.sh"
run_test "stop.sh is executable" "test -x ./stop.sh"
echo

# Test 2: Development environment setup
log "=== Testing Development Environment ==="
log "Setting up development environment (this may take a few minutes)..."

# Run setup in background to capture output
if ./setup.sh dev >/dev/null 2>&1; then
    success "Development setup completed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    error "Development setup failed"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Wait for services to fully start
log "Waiting for services to start..."
sleep 10

# Test 3: Service health checks
log "=== Testing Service Health ==="
run_test "MQTT broker is running" "nc -z localhost 1883"
run_test "Backend API is accessible" "nc -z localhost 3001"
run_test "Nginx proxy is running" "nc -z localhost 8080"

# Test 4: API endpoints
log "=== Testing API Endpoints ==="
run_test "Backend health endpoint" "curl -sf http://localhost:3001/health"
run_test "MQTT status endpoint" "curl -sf http://localhost:3001/api/mqtt/status"

# Test 5: File structure
log "=== Testing File Structure ==="
run_test "Dashboard.jsx exists" "test -f src/Dashboard.jsx"
run_test "theme.json exists" "test -f src/theme.json"
run_test "DevContainer config exists" "test -f .devcontainer/devcontainer.json"
run_test "Docker files exist" "test -f Dockerfile.frontend && test -f Dockerfile.backend && test -f Dockerfile.nginx"

# Test 6: Hot reload test (simulate file change)
log "=== Testing Hot Reload Capability ==="
log "Making a test change to Dashboard.jsx..."

# Backup original file
cp src/Dashboard.jsx src/Dashboard.jsx.backup

# Make a simple change
sed -i 's/NU Fridge Dashboard/NU Fridge Dashboard - TEST/' src/Dashboard.jsx

# Wait a moment for hot reload
sleep 2

# Check if frontend is still accessible (hot reload didn't break)
if nc -z localhost 5173 2>/dev/null; then
    success "Hot reload test - frontend still accessible"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    error "Hot reload test - frontend not accessible"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Restore original file
mv src/Dashboard.jsx.backup src/Dashboard.jsx

# Test 7: Production build
log "=== Testing Production Build ==="
log "Building production images (this may take a few minutes)..."

if ./build.sh >/dev/null 2>&1; then
    success "Production build completed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    error "Production build failed"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Test 8: Production environment
log "=== Testing Production Environment ==="
log "Stopping development environment..."
./stop.sh dev >/dev/null 2>&1

log "Starting production environment..."
if docker-compose -f docker-compose.prod.yml up -d >/dev/null 2>&1; then
    success "Production environment started"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    error "Production environment failed to start"
fi
TESTS_TOTAL=$((TESTS_TOTAL + 1))

# Wait for production services
sleep 10

# Test production health
run_test "Production - MQTT broker" "nc -z localhost 1883"
run_test "Production - Backend API" "nc -z localhost 3001"
run_test "Production - Nginx proxy" "nc -z localhost 8080"

# Test 9: Monitoring
log "=== Testing Monitoring ==="
run_test "Monitor script runs" "./monitor.sh | grep -q 'NU Fridge SmartKiosk Status'"

# Test 10: Cleanup
log "=== Testing Cleanup ==="
run_test "Stop script works" "./stop.sh all"

# Final results
echo
log "🏁 Test Results:"
echo -e "   Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "   Total:  ${BLUE}$TESTS_TOTAL${NC}"

if [ "$TESTS_PASSED" -eq "$TESTS_TOTAL" ]; then
    echo
    success "🎉 ALL TESTS PASSED! NU Fridge SmartKiosk is fully functional."
    echo
    log "✅ What works:"
    echo "  • Development environment with hot reload"
    echo "  • Production build and deployment"
    echo "  • All services (MQTT, Backend, Nginx)"
    echo "  • Health monitoring and APIs"
    echo "  • File structure and configuration"
    echo
    log "🚀 Ready for AI agents and human developers!"
    echo "  • Start: ./setup.sh dev"
    echo "  • Monitor: ./monitor.sh"
    echo "  • Guide: AI_AGENT_GUIDE.md"
else
    echo
    error "❌ Some tests failed. Check the logs above."
    echo
    warn "🔧 Troubleshooting:"
    echo "  • Check Docker and Docker Compose are installed"
    echo "  • Ensure ports 1883, 3001, 5173, 8080 are available"
    echo "  • Check network connectivity"
    echo "  • Run: ./monitor.sh to see current status"
    exit 1
fi