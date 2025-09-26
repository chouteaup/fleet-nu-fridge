# NU Fridge SmartKiosk - AI Agent Guide

Documentation complète pour agents IA travaillant sur cette plateforme.

## Quick Start for AI Agents

```bash
# 1. Setup development environment
./setup.sh dev

# 2. Monitor status
./monitor.sh

# 3. Make changes to src/ files

# 4. See results instantly on http://localhost:5173 (hot reload)

# 5. Build production images
./build.sh
```

## Architecture Overview for AI

```
NU Fridge SmartKiosk
├── src/                     # 🎯 MODIFY HERE - Tenant customizations
│   ├── Dashboard.jsx        # React main dashboard
│   ├── theme.json          # Visual theme & branding
│   ├── components/         # Custom React components
│   ├── assets/            # Images, icons
│   └── config/            # Configuration files
├── Dockerfile.frontend     # Frontend build (inherits SmartKiosk Core)
├── Dockerfile.backend      # Backend build (inherits SmartKiosk Core)
├── Dockerfile.nginx        # Nginx build (inherits SmartKiosk Core)
├── docker-compose.dev.yml  # Development with hot reload
├── docker-compose.prod.yml # Production build
└── scripts/               # Automation scripts
    ├── setup.sh          # 🚀 Setup environment
    ├── monitor.sh        # 📊 Real-time monitoring
    └── build.sh          # 🏗️  Build images
```

## How to Modify Each Component

### 🎨 Frontend Modifications

**File: `src/Dashboard.jsx`**
```jsx
// This is the main UI component
import React from 'react';
import { Thermometer, Package, AlertTriangle } from 'lucide-react';

export default function TenantDashboard() {
  return (
    <div className="tenant-dashboard">
      <h1>NU Fridge Dashboard</h1>
      {/* Add your widgets here */}
    </div>
  );
}
```

**How to see changes:**
1. Modify `src/Dashboard.jsx`
2. Changes appear instantly on http://localhost:5173 (hot reload)
3. Check browser console for any errors

**File: `src/theme.json`**
```json
{
  "name": "NU Fridge Theme",
  "colors": {
    "primary": "#0891b2",    // Main color
    "secondary": "#0e7490",  // Secondary color
    "accent": "#06b6d4"      // Accent color
  }
}
```

**Adding new components:**
1. Create file in `src/components/MyComponent.jsx`
2. Import in `src/Dashboard.jsx`: `import MyComponent from './components/MyComponent.jsx'`
3. Use in render: `<MyComponent />`

### 🛠️ Backend Modifications

The backend inherits from SmartKiosk Core. To add custom APIs:

**File: `src/api-routes.js` (create if needed)**
```javascript
// Custom API routes for NU Fridge
export const customRoutes = {
  '/api/fridge/temperature': {
    method: 'GET',
    handler: () => ({ temperature: 4.2, unit: 'C' })
  },
  '/api/fridge/inventory': {
    method: 'GET',
    handler: () => ({ items: ['milk', 'eggs', 'cheese'] })
  }
};
```

**File: `src/config.js` (create if needed)**
```javascript
// Backend configuration
export const config = {
  fridgeSettings: {
    minTemp: 2,
    maxTemp: 8,
    alertThreshold: 10
  },
  mqtt: {
    topics: {
      temperature: 'nufridge/temperature',
      door: 'nufridge/door'
    }
  }
};
```

**How to test backend changes:**
1. Restart backend: `docker-compose restart backend`
2. Test API: `curl http://localhost:3001/api/fridge/temperature`
3. Check logs: `docker-compose logs backend`

### 🌐 Nginx Configuration

**File: `src/nginx.conf` (create if needed)**
```nginx
# Custom nginx configuration for NU Fridge
location /fridge-api/ {
    proxy_pass http://backend:3001/api/fridge/;
    proxy_set_header Host $host;
}

location /fridge-assets/ {
    alias /app/tenant/assets/;
    expires 1d;
}
```

**How to apply nginx changes:**
1. Restart nginx: `docker-compose restart nginx`
2. Test: `curl http://localhost:8080/fridge-api/temperature`

## AI Agent APIs

### Health Monitoring
```bash
# Check if system is healthy
curl http://localhost:3001/health

# Expected response: {"status":"ok","timestamp":"2025-01-01T12:00:00Z"}
```

### MQTT Integration
```bash
# Check MQTT status
curl http://localhost:3001/api/mqtt/status

# Send MQTT message
curl -X POST http://localhost:3001/api/mqtt/send \
  -H "Content-Type: application/json" \
  -d '{"topic": "nufridge/test", "message": "Hello from AI"}'

# Get mock device data
curl http://localhost:3001/api/mock/devices | jq
```

### Real-time Monitoring
```bash
# Get system status
./monitor.sh

# Continuous monitoring
./monitor.sh --watch

# Check logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f nginx
```

## Development Workflow for AI Agents

### 1. Environment Setup
```bash
# Clone repository
git clone https://github.com/chouteaup/fleet-nu-fridge.git
cd fleet-nu-fridge

# Setup development environment
./setup.sh dev

# Verify everything is running
./monitor.sh
```

### 2. Make Frontend Changes
```bash
# Edit main dashboard
vim src/Dashboard.jsx

# See changes instantly
# Open http://localhost:5173 in browser
# Changes appear automatically (hot reload)
```

### 3. Make Backend Changes
```bash
# Add custom API routes
vim src/api-routes.js

# Restart backend to apply changes
docker-compose restart backend

# Test new API
curl http://localhost:3001/api/fridge/temperature
```

### 4. Make Nginx Changes
```bash
# Edit nginx configuration
vim src/nginx.conf

# Restart nginx
docker-compose restart nginx

# Test new routes
curl http://localhost:8080/fridge-api/temperature
```

### 5. Build and Test Production
```bash
# Build production images
./build.sh

# Stop development environment
docker-compose -f docker-compose.dev.yml down

# Start production environment
docker-compose -f docker-compose.prod.yml up -d

# Test production
./monitor.sh
```

### 6. Validate Changes
```bash
# Run health checks
curl http://localhost:3001/health

# Check all services
./monitor.sh

# Test user interface
open http://localhost:8080
```

## File Change Detection

AI agents can monitor file changes and trigger actions:

```bash
# Watch for file changes (requires inotify-tools)
inotifywait -m -r -e modify src/ | while read path action file; do
    echo "File changed: $path$file"
    # Trigger specific actions based on file type
    case "$file" in
        *.jsx|*.js) echo "Frontend change detected" ;;
        *.json) echo "Config change detected" ;;
        *.conf) echo "Nginx change detected" && docker-compose restart nginx ;;
    esac
done
```

## Error Handling

### Common Issues and Solutions

**Container not starting:**
```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs <service-name>

# Restart service
docker-compose restart <service-name>
```

**Hot reload not working:**
```bash
# Restart frontend container
docker-compose restart frontend

# Check if port 5173 is accessible
curl http://localhost:5173
```

**API not responding:**
```bash
# Check backend health
curl http://localhost:3001/health

# Check backend logs
docker-compose logs backend

# Restart backend
docker-compose restart backend
```

**Build failing:**
```bash
# Check build logs
docker-compose -f docker-compose.prod.yml build --no-cache

# Check Docker images
docker images | grep nufridge
```

## Advanced AI Agent Integration

### WebSocket for Real-time Updates
```javascript
// Connect to real-time updates
const ws = new WebSocket('ws://localhost:3001/ws');
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Real-time update:', data);
};
```

### MQTT Direct Connection
```javascript
// Connect to MQTT directly
import mqtt from 'mqtt';
const client = mqtt.connect('mqtt://localhost:1883');

client.on('message', (topic, message) => {
    console.log(`Message from ${topic}: ${message.toString()}`);
});

client.subscribe('nufridge/+/+');
```

### Automated Testing
```bash
# Run integration tests
npm test 2>/dev/null || echo "Tests not configured yet"

# Manual API testing
curl -s http://localhost:3001/health | jq '.status'
```

## Success Criteria for AI Agents

✅ **Environment Setup**: `./setup.sh dev` completes without errors
✅ **Services Running**: All containers show "Up" in `docker-compose ps`
✅ **Hot Reload Works**: Changes to `src/Dashboard.jsx` appear instantly on http://localhost:5173
✅ **API Responds**: `curl http://localhost:3001/health` returns `{"status":"ok"}`
✅ **MQTT Works**: Can send/receive messages via `curl` to MQTT API
✅ **Production Build**: `./build.sh` completes without errors
✅ **Monitoring**: `./monitor.sh` shows all services as UP

## Next Steps

1. **Setup environment**: `./setup.sh dev`
2. **Verify with monitoring**: `./monitor.sh`
3. **Make a test change**: Edit `src/Dashboard.jsx`
4. **See results**: Check http://localhost:5173
5. **Build production**: `./build.sh`

This guide provides everything an AI agent needs to understand, modify, and work with the NU Fridge SmartKiosk platform.