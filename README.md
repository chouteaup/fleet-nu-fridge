# NU Fridge - Fleet IoT Tenant

Projet tenant pour l'équipe NU développant un simulateur de réfrigérateur basé sur la plateforme Fleet IoT.

## 🏗️ Architecture

Ce projet implémente le **système d'héritage modules tenant** selon les spécifications Fleet 2025 :

- **Héritage Docker FROM** : Images basées sur Fleet Core
- **DevContainer autonome** : Environnement de développement isolé
- **dev-manager avec héritage** : Réutilisation des fonctions Fleet Core
- **Maintenance évolutive** : Synchronisation automatique Fleet Core

## 🚀 Démarrage Rapide

### 1. DevContainer Setup

```bash
# Ouvrir dans VS Code
code .

# Sélectionner "Reopen in Container"
# Le setup Fleet Core s'exécute automatiquement
```

### 2. Développement Simulator

```bash
# Lancer le simulateur en mode développement
cd modules/Simulator
./dev-manager.sh dev ../../config/fridge-dev.json

# Accéder au simulateur
# http://localhost:5174
```

### 3. Services Fleet Core

Le DevContainer lance automatiquement :
- **Fleet Backend** : http://localhost:3001
- **Fleet MQTT Hub** : mqtt://localhost:1883 (WebSocket: ws://localhost:9001)

## 📁 Structure Projet

```
tenants/NU/Fridge/
├── .devcontainer/              # DevContainer autonome
│   ├── devcontainer.json       # Configuration VS Code
│   ├── docker-compose.yml      # Services intégrés
│   └── Dockerfile.dev          # Image dev tenant
├── modules/
│   └── Simulator/              # Module tenant
│       ├── dev-manager.sh      # Héritage Frontend core
│       ├── Dockerfile          # FROM fleet-core/frontend
│       ├── src/                # Application React
│       │   ├── App.jsx         # Interface Simulator
│       │   └── main.jsx
│       └── package.json        # Dependencies tenant
├── config/
│   └── fridge-dev.json         # Configuration tenant
├── scripts/
│   ├── setup-fleet-core.sh     # Clone/sync Fleet Core
│   ├── sync-dev-manager.sh     # Sync fonctions core
│   └── image-manager.sh        # Gestion images tenant
└── fleet.code-workspace        # Workspace VS Code
```

## 🔧 Workflows Développement

### Mode Développement

```bash
# Simulator avec hot-reload (port 5174)
cd modules/Simulator
./dev-manager.sh dev ../../config/fridge-dev.json
```

### Mode Production

```bash
# Build image tenant
scripts/image-manager.sh build config/fridge-dev.json Simulator

# Run container tenant
scripts/image-manager.sh run config/fridge-dev.json Simulator
```

### Synchronisation Fleet Core

```bash
# Mise à jour Fleet Core (automatique au démarrage)
scripts/setup-fleet-core.sh

# Sync fonctions dev-manager (automatique)
scripts/sync-dev-manager.sh
```

## 🌐 Configuration Tenant

### Variables d'Environnement

- `TENANT="NU"` - Identité équipe
- `PROJECT="Fridge"` - Nom projet
- `VITE_PORT=5174` - Port dédié (évite conflits avec Fleet Core:5173)
- `VITE_TENANT_NAME="NU Fridge"` - Nom affiché interface

### Ports Dédiés

- **5174** : Simulator Frontend (tenant)
- **3001** : Fleet Backend API (partagé)
- **1883** : MQTT Broker (partagé)
- **9001** : MQTT WebSocket (partagé)

## 🐳 Docker & ACR

### Images Fleet Core Héritées

- Base : `acrfleetcoredev.azurecr.io/fleet-core/frontend:dev-amd64`
- Tenant : `acrfleetcoredev.azurecr.io/fleet-tenant/nu-simulator:dev-amd64`

### Héritage Dockerfile

```dockerfile
FROM acrfleetcoredev.azurecr.io/fleet-core/frontend:dev-amd64
COPY src/ ./src/              # Surcharge application React
EXPOSE 5174                   # Port tenant dédié
```

## 🔄 Maintenance Évolutive

### Synchronisation Automatique

1. **postCreateCommand** : `setup-fleet-core.sh`
2. **postStartCommand** : `sync-dev-manager.sh`
3. **Fonctions extraites** : Marqueurs `REUSABLE_FUNCTIONS_START/END`

### Héritage dev-manager

Le dev-manager tenant **source automatiquement** les fonctions Fleet Core :
- `install_dependencies()`
- `check_dev_script()`
- `start_dev_server()`

## 📊 Développement

### Features Simulator

- Interface React avec Tailwind CSS
- Simulation température réfrigérateur
- Contrôles compresseur
- État connexion MQTT
- Configuration tenant intégrée

### Extensions VS Code

- IoT spécialisées : `mqttx.vscode-mqttx`, `vsciot-vscode.azure-iot-tools`
- React/TypeScript : `ms-vscode.vscode-typescript-next`
- Docker : `ms-azuretools.vscode-docker`

## 🎯 URLs Développement

- **Simulator** : http://localhost:5174 (hot-reload)
- **Fleet Backend** : http://localhost:3001/api/*
- **MQTT Test** : `mosquitto_sub -h localhost -t 'test/+' -v`

---

**Architecture** : Fleet IoT Platform 2025 - Système Modules Tenant
**Équipe** : NU Fridge
**Base Module** : Frontend