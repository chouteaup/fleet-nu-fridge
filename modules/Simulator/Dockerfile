ARG BASE_IMAGE=acrfleetcoredev.azurecr.io/fleet-core/frontend:dev-amd64
FROM ${BASE_IMAGE}

# Métadonnées tenant
LABEL tenant="NU"
LABEL module="Simulator"
LABEL base_module="Frontend"
LABEL version="1.0.0"

WORKDIR /app

# Dependencies tenant
COPY package.json package.tenant.json* ./
RUN npm install --only=production

# Application React tenant
COPY src/ ./src/
COPY config/ ./config/ 2>/dev/null || true
COPY vite.config.js ./

# Variables d'environnement tenant
ENV VITE_PORT=5174
ENV VITE_TENANT=NU
ENV VITE_TENANT_NAME="NU Fridge"
ENV VITE_BACKEND_URL="http://localhost:3001"
ENV VITE_MQTT_URL="ws://localhost:9001"

EXPOSE 5174

CMD ["npm", "run", "dev", "--", "--port", "5174"]