# NU Fridge Smart Kiosk

Smart Kiosk tenant pour la gestion de frigos connectés NU Fridge.

## Développement Ultra-Simple

### Prérequis
- Docker et Docker Compose
- VS Code avec l'extension Dev Containers (optionnel)

### Lancement Automatisé en 3 Étapes
```bash
# 1. Authentification Azure
az login
az acr login --name acrfleetcoredev

# 2. Démarrage environnement
./setup.sh dev
```

**C'est tout ! L'environnement complet démarre automatiquement.**

### Workflow Équipe Mixte (Humains + IA)
```bash
# 1. Authentification (une seule fois)
az login && az acr login --name acrfleetcoredev

# 2. Setup environnement
./setup.sh dev

# 3. Monitoring en temps réel
./monitor.sh

# 4. Modifications (humains ou agents IA)
# Modifier src/Dashboard.jsx → Hot reload instantané
# Modifier src/theme.json → Thème mis à jour
# Ajouter src/components/ → Nouveaux composants

# 4. Build production
./build.sh

# 5. Test complet
./test-workflow.sh
```

### Scripts Disponibles
- `./setup.sh [dev|prod]` - Setup environnement
- `./monitor.sh [--watch]` - Monitoring système
- `./build.sh` - Build images production
- `./stop.sh [dev|prod|all]` - Arrêt environnement
- `./test-workflow.sh` - Test complet
- `./help.sh` - Aide et commandes

### Documentation IA
- **[AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md)** - Guide complet pour agents IA
- **APIs REST** disponibles pour automation
- **Hot reload** pour feedback instantané
- **Monitoring** en temps réel des modifications

## Architecture Multi-Images Fleet Core

### Évolution Architecturale 🆕

**AVANT** (Docker-in-Docker complexe):
- 1 image monolithique avec orchestrateur Docker-in-Docker
- Privilèges `privileged: true` requis
- Complexité de debugging et maintenance élevée

**MAINTENANT** (Multi-images simplifiées):
- 4 images séparées héritant de Fleet Core ACR
- Aucun privilège spécial requis
- Architecture plus sûre, scalable et maintenable

### Images Fleet Core Héritées

Ce tenant étend les images Fleet Core depuis Azure Container Registry :
- **Backend**: `acrfleetcoredev.azurecr.io/fleetcore-backend:latest`
- **Frontend**: `acrfleetcoredev.azurecr.io/fleetcore-frontend:latest`
- **Web (Nginx)**: `acrfleetcoredev.azurecr.io/fleetcore-web:latest`
- **Kiosk (Chromium)**: `acrfleetcoredev.azurecr.io/fleetcore-kiosk:latest`
- **Hub (MQTT)**: `acrfleetcoredev.azurecr.io/fleetcore-hub:latest`

### Bénéfices Multi-Images

✅ **Simplicité**: Chaque service = 1 container dédié
✅ **Sécurité**: Plus de Docker-in-Docker privilégié
✅ **Performance**: Images légères avec héritage Fleet Core
✅ **Maintenance**: Mises à jour Core indépendantes
✅ **Debugging**: Logs et monitoring par service
✅ **Scalabilité**: Scaling horizontal par composant

## Personnalisation NU Fridge

### Interface Utilisateur
- **Dashboard personnalisé**: Monitoring temperature, inventaire, consommation énergétique
- **Thème NU**: Couleurs cyan/blue, branding NU Fridge
- **Composants spécifiques**: Widgets frigo connecté

### Fonctionnalités
- Monitoring température en temps réel
- Suivi inventaire produits
- Alertes d'expiration
- Optimisation énergétique
- Planification maintenance

### URLs de développement
- Frontend: http://localhost:5173 (Hot reload)
- Backend API: http://localhost:3001
- Interface complète: http://localhost:8080
- MQTT: mqtt://localhost:1883

## Structure des fichiers

```
├── src/                        # Customizations NU Fridge
│   ├── backend/                # Extensions API backend
│   │   └── routes.js           # Routes tenant spécifiques
│   ├── frontend/               # Customizations React
│   │   └── index.html          # Page d'accueil NU Fridge
│   ├── nginx/                  # Configuration Nginx
│   │   └── tenant.conf         # Proxy rules tenant
│   ├── kiosk/                  # Configuration affichage kiosk
│   ├── assets/                 # Assets spécifiques NU
│   ├── config/                 # Configuration tenant
│   └── static/                 # Fichiers statiques
├── Dockerfile.backend          # FROM fleetcore-backend:latest
├── Dockerfile.frontend         # FROM fleetcore-frontend:latest
├── Dockerfile.web              # FROM fleetcore-web:latest
├── Dockerfile.kiosk            # FROM fleetcore-kiosk:latest
├── docker-compose.dev.yml      # Développement (multi-services)
├── docker-compose.prod.yml     # Production (héritage Fleet Core)
└── build.sh                    # Build script multi-images
```

### Architecture de Service

```
┌─────────────────────────────────────────┐
│         NU FRIDGE ARCHITECTURE          │
│  ┌─────────────────────────────────────┐│
│  │         KIOSK DISPLAY               ││
│  │  • Chromium en mode kiosk           ││
│  │  • Affichage plein écran            ││
│  │  • FROM fleetcore-kiosk:latest      ││
│  └─────────────────────────────────────┘│
│           ▲                             │
│           │ HTTP                        │
│  ┌─────────────────────────────────────┐│
│  │         WEB PROXY                   ││
│  │  • Nginx reverse proxy             ││
│  │  • SSL/TLS + gzip                  ││
│  │  • FROM fleetcore-web:latest       ││
│  └─────────────────────────────────────┘│
│     ▲                        ▲          │
│     │ /api/*                 │ /*       │
│  ┌─────────────┐    ┌─────────────────┐│
│  │   BACKEND   │    │    FRONTEND     ││
│  │ Node.js API │    │ React SPA       ││
│  │ MQTT Bridge │    │ NU Fridge UI    ││
│  │ Core + Ext. │    │ Core + Custom   ││
│  └─────────────┘    └─────────────────┘│
│         ▲                              │
│         │ MQTT                         │
│  ┌─────────────────────────────────────┐│
│  │         HUB MQTT                    ││
│  │  • Mosquitto 2.0                   ││
│  │  • WebSocket support               ││
│  │  • FROM fleetcore-hub:latest       ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Modes de Fonctionnement

### Développement (Multi-Services)
```bash
# Démarrer tous les services de développement
docker-compose -f docker-compose.dev.yml up -d

# Monitoring des services
docker-compose -f docker-compose.dev.yml ps

# Logs de tous les services
docker-compose -f docker-compose.dev.yml logs -f

# Logs d'un service spécifique
docker-compose -f docker-compose.dev.yml logs -f backend-dev
```

**Services disponibles en développement:**
- `backend-dev`: API Node.js avec hot reload
- `frontend-dev`: Interface React avec HMR
- `web-dev`: Nginx proxy avec configuration tenant
- `hub`: MQTT broker Mosquitto

### Production (Images Optimisées)
```bash
# Build toutes les images tenant
./build.sh --tag=v1.0.0

# Ou build spécifique
docker-compose -f docker-compose.prod.yml build

# Deploy production
docker-compose -f docker-compose.prod.yml up -d

# Avec monitoring kiosk
docker-compose -f docker-compose.prod.yml up -d kiosk
```

**Services production:**
- `backend`: API optimisée avec extensions tenant
- `frontend`: SPA React avec customisations intégrées
- `web`: Nginx proxy avec SSL/TLS et compression
- `kiosk`: Affichage Chromium en mode kiosk
- `hub`: MQTT broker avec persistance

### Commandes Utiles

```bash
# Test de l'architecture
curl http://localhost:3001/health              # Backend health
curl http://localhost:3000                     # Frontend direct
curl http://localhost:8080                     # Via proxy web
curl http://localhost:8080/api/health          # API via proxy

# MQTT testing
mosquitto_pub -h localhost -t "test" -m "hello"
mosquitto_sub -h localhost -t "test" -C 1

# Build et test complet
./build.sh && docker-compose -f docker-compose.prod.yml up -d
```

## Support

- Email: support@nufridge.example.com
- Documentation Core: [Fleet IoT Platform](../../README.md)