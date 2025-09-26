# NU Fridge Smart Kiosk

Smart Kiosk tenant pour la gestion de frigos connectés NU Fridge.

## Développement Ultra-Simple

### Prérequis
- Docker et Docker Compose
- VS Code avec l'extension Dev Containers (optionnel)

### Lancement Automatisé en 1 Étape
```bash
./setup.sh dev
```

**C'est tout ! L'environnement complet démarre automatiquement.**

### Workflow Équipe Mixte (Humains + IA)
```bash
# 1. Setup environnement
./setup.sh dev

# 2. Monitoring en temps réel
./monitor.sh

# 3. Modifications (humains ou agents IA)
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

## Architecture

Ce tenant hérite des images SmartKiosk Core depuis l'Azure Container Registry :
- `acrfleetcoredev.azurecr.io/smartkiosk-frontend:latest`
- `acrfleetcoredev.azurecr.io/smartkiosk-backend:latest`
- `acrfleetcoredev.azurecr.io/smartkiosk-nginx:latest`
- `acrfleetcoredev.azurecr.io/smartkiosk-hub:latest`

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
│   ├── Dashboard.jsx           # Dashboard NU Fridge personnalisé
│   ├── theme.json              # Thème et branding NU
│   ├── components/             # Composants React custom
│   ├── assets/                 # Assets spécifiques NU
│   └── config/                 # Configuration tenant
├── Dockerfile.frontend         # FROM SmartKiosk Core Frontend
├── Dockerfile.backend          # FROM SmartKiosk Core Backend
├── Dockerfile.nginx            # FROM SmartKiosk Core Nginx
├── docker-compose.dev.yml      # Développement (volumes mount)
└── docker-compose.prod.yml     # Production (héritage FROM)
```

## Modes de Fonctionnement

### Développement (Hot Reload)
```bash
# DevContainer ultra-simple
code .  # → "Reopen in Container" → Développement instantané

# Ou docker-compose manuel
docker-compose -f docker-compose.dev.yml up -d
```

Les customizations dans `src/` sont montées comme volumes et reflétées instantanément.

### Production (Héritage Images)
```bash
# Build tenant avec héritage SmartKiosk Core
docker-compose -f docker-compose.prod.yml build

# Deploy production
docker-compose -f docker-compose.prod.yml up -d
```

Les customizations sont intégrées dans les images via `COPY src/ /app/tenant/`.

## Support

- Email: support@nufridge.example.com
- Documentation Core: [Fleet IoT Platform](../../README.md)