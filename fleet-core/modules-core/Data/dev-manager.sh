#!/bin/bash
# Data Module - Development Manager
# Responsabilité locale pour le module Data SQLite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[Data] ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}[Data] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[Data] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[Data] ⚠️  $1${NC}"
}

# Usage
usage() {
    echo "Data Module Development Manager"
    echo ""
    echo "Usage: $0 MODE CONFIG_FILE"
    echo ""
    echo "Modes:"
    echo "  dev  - Launch in development mode (local SQLite + init)"
    echo "  run  - Launch from ACR image"
}

# Development mode
dev_mode() {
    local config_file="$1"

    print_info "Starting Data module in development mode"

    # Create data directory if it doesn't exist
    if [[ ! -d "/data" ]]; then
        print_info "Creating data directory..."
        mkdir -p "./data"
        print_success "Data directory created: ./data"
    fi

    # Check if SQLite is available
    if ! command -v sqlite3 &> /dev/null; then
        print_warning "sqlite3 not found locally, using Docker approach"

        # Build and run with Docker
        local image_name="fleet-data-dev"
        local container_name="fleet-data-dev"

        # Stop existing container
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true

        # Build if needed
        if ! docker image inspect "$image_name" >/dev/null 2>&1; then
            print_info "Building Data image..."
            docker build -t "$image_name" .
        fi

        # Run container with volume
        if docker run -d --name "$container_name" \
            -v "$(pwd)/data:/data" \
            -p 5432:5432 \
            "$image_name"; then
            print_success "Data container started"
            print_success "SQLite database available at ./data/fleet.db"
        else
            print_error "Failed to start Data container"
            exit 1
        fi
    else
        # Local SQLite development
        print_info "Using local SQLite for development"

        # Create SQL schema if missing
        if [[ ! -f "sql/init.sql" ]]; then
            print_info "Creating default Fleet database schema..."
            mkdir -p sql
            create_fleet_schema
        fi

        # Initialize database if it doesn't exist
        if [[ ! -f "./data/fleet.db" ]]; then
            print_info "Initializing Fleet SQLite database..."
            sqlite3 "./data/fleet.db" < "sql/init.sql"
            print_success "Fleet database initialized with schema"
        fi

        print_success "Fleet Data module ready"
        print_info "SQLite Database: ./data/fleet.db"
        print_info ""
        print_info "Database operations:"
        print_info "  📊 Connect: sqlite3 ./data/fleet.db"
        print_info "  📋 Tables: devices, telemetry, configurations"
        print_info "  🔍 Query devices: SELECT * FROM devices;"
        print_info "  📈 Query telemetry: SELECT * FROM telemetry ORDER BY timestamp DESC LIMIT 10;"

        # Show current database stats
        if [[ -f "./data/fleet.db" ]]; then
            device_count=$(sqlite3 "./data/fleet.db" "SELECT COUNT(*) FROM devices;" 2>/dev/null || echo "0")
            telemetry_count=$(sqlite3 "./data/fleet.db" "SELECT COUNT(*) FROM telemetry;" 2>/dev/null || echo "0")
            print_info ""
            print_info "Current data:"
            print_info "  🎯 Devices: $device_count"
            print_info "  📊 Telemetry records: $telemetry_count"
        fi

        print_info ""
        print_info "Data module running... (Ctrl+C to stop)"

        # Keep running and show live stats every 30 seconds
        while true; do
            sleep 30
            if [[ -f "./data/fleet.db" ]]; then
                timestamp=$(date '+%H:%M:%S')
                devices=$(sqlite3 "./data/fleet.db" "SELECT COUNT(*) FROM devices;" 2>/dev/null || echo "0")
                telemetry=$(sqlite3 "./data/fleet.db" "SELECT COUNT(*) FROM telemetry;" 2>/dev/null || echo "0")
                print_info "[$timestamp] Fleet DB Status - Devices: $devices, Telemetry: $telemetry"
            fi
        done
    fi
}

# Create Fleet database schema
create_fleet_schema() {
    cat > sql/init.sql << 'EOF'
-- Fleet Core Database Schema
-- SQLite database for IoT device management

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Devices table - Core device registry
CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'raspberry-pi',
    status TEXT DEFAULT 'offline' CHECK(status IN ('online', 'offline', 'maintenance', 'error')),
    last_seen DATETIME,
    configuration TEXT, -- JSON configuration
    location TEXT,
    firmware_version TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Telemetry table - Device metrics and sensor data
CREATE TABLE IF NOT EXISTS telemetry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metric_name TEXT NOT NULL,
    metric_value REAL,
    metric_unit TEXT,
    FOREIGN KEY (device_id) REFERENCES devices (id) ON DELETE CASCADE
);

-- Configuration table - System and tenant configurations
CREATE TABLE IF NOT EXISTS configurations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL, -- JSON value
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_telemetry_device_id ON telemetry(device_id);
CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON telemetry(timestamp);
CREATE INDEX IF NOT EXISTS idx_telemetry_device_time ON telemetry(device_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_type ON devices(type);
CREATE INDEX IF NOT EXISTS idx_configurations_key ON configurations(key);

-- Sample Fleet data
INSERT OR IGNORE INTO devices (id, name, type, status, location) VALUES
('pi5-001', 'Raspberry Pi 001', 'raspberry-pi', 'online', 'Building A - Floor 1'),
('pi5-002', 'Raspberry Pi 002', 'raspberry-pi', 'offline', 'Building A - Floor 2'),
('pi5-003', 'Raspberry Pi 003', 'raspberry-pi', 'maintenance', 'Building B - Floor 1');

-- Sample telemetry data
INSERT OR IGNORE INTO telemetry (device_id, metric_name, metric_value, metric_unit) VALUES
('pi5-001', 'cpu_usage', 45.2, 'percent'),
('pi5-001', 'memory_usage', 67.8, 'percent'),
('pi5-001', 'temperature', 52.1, 'celsius'),
('pi5-002', 'cpu_usage', 23.1, 'percent'),
('pi5-002', 'memory_usage', 34.5, 'percent');

-- Sample configurations
INSERT OR IGNORE INTO configurations (key, value, description) VALUES
('fleet.mqtt.broker', '{"host": "localhost", "port": 1883}', 'MQTT broker configuration'),
('fleet.telemetry.interval', '30', 'Telemetry collection interval in seconds'),
('fleet.log.level', 'info', 'System logging level');

-- Create views for common queries
CREATE VIEW IF NOT EXISTS device_summary AS
SELECT
    d.id,
    d.name,
    d.status,
    d.location,
    COUNT(t.id) as telemetry_count,
    MAX(t.timestamp) as last_telemetry
FROM devices d
LEFT JOIN telemetry t ON d.id = t.device_id
GROUP BY d.id, d.name, d.status, d.location;

-- Triggers for updated_at timestamps
CREATE TRIGGER IF NOT EXISTS update_devices_timestamp
    AFTER UPDATE ON devices
BEGIN
    UPDATE devices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_configurations_timestamp
    AFTER UPDATE ON configurations
BEGIN
    UPDATE configurations SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
EOF
    print_success "Fleet database schema created in sql/init.sql"
}

# Run mode
run_mode() {
    local config_file="$1"

    print_info "Starting Data in run mode (ACR image)"

    # Delegate to image manager
    local image_manager="../../image-manager.sh"

    if [[ ! -f "$image_manager" ]]; then
        print_error "Image manager not found: $image_manager"
        exit 1
    fi

    # Execute image manager
    "$image_manager" run "$config_file" Data
}

# Main execution
main() {
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    local mode="$1"
    local config_file="$2"

    # Validate config file
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    case "$mode" in
        "dev")
            dev_mode "$config_file"
            ;;
        "run")
            run_mode "$config_file"
            ;;
        *)
            print_error "Unknown mode: $mode"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"