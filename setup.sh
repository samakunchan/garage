#!/bin/bash

# Read arguments (default to 'dev' and 'localhost')
ENV=${1:-"dev"}
DOMAIN=${2:-"localhost"}

# Determine sudo prefix based on env
if [ "$ENV" = "prod" ]; then
  SUDO_PREFIX="sudo "
else
  SUDO_PREFIX=""
fi

# 1. Génération des secrets
RPC_SECRET=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -hex 32)

# Determine root domains
if [ "$ENV" = "prod" ] && [ "$DOMAIN" != "localhost" ]; then
  ROOT_DOMAIN_API=".s3.$DOMAIN"
  ROOT_DOMAIN_WEB=".web.$DOMAIN"
else
  ROOT_DOMAIN_API=".s3.garage.localhost"
  ROOT_DOMAIN_WEB=".web.garage.localhost"
fi

# 2. Création du fichier de configuration garage.toml
cat <<EOF > garage.toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "[::]:3901"
rpc_secret = "$RPC_SECRET"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = "$ROOT_DOMAIN_API"

[s3_web]
bind_addr = "[::]:3902"
root_domain = "$ROOT_DOMAIN_WEB"

[admin]
api_bind_addr = "0.0.0.0:3903"
admin_token = "$ADMIN_TOKEN"
EOF

# 3. Création du compose.yml
cat <<EOF > compose.yml
services:
  garage:
    image: dxflrs/garage:v2.3.0
    container_name: garage
    ports:
      - "3900:3900"
      - "3901:3901"
      - "3902:3902"
      - "3903:3903"
    volumes:
      - ./garage.toml:/etc/garage.toml:ro
      - garage_meta:/var/lib/garage/meta
      - garage_data:/var/lib/garage/data
    networks:
      - nginx-proxy-network
    restart: always

volumes:
  garage_meta:
    driver: local
  garage_data:
    driver: local

networks:
  nginx-proxy-network:
    external: true
EOF

echo "✅ Configuration terminée ($ENV mode)."
echo "🔑 Admin Token : $ADMIN_TOKEN"
echo "🚀 Pour démarrer : ${SUDO_PREFIX}docker compose up -d"
echo "⚙️  Ensuite, configurez le layout :"
echo "   ${SUDO_PREFIX}docker exec -it garage /garage layout assign --zone dc1 --capacity 10G \$(${SUDO_PREFIX}docker exec garage /garage node id | cut -d'@' -f1)"
echo "   ${SUDO_PREFIX}docker exec -it garage /garage layout apply --version 1"



