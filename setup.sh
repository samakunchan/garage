#!/bin/bash

# 1. Génération des secrets
RPC_SECRET=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -hex 32)

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
root_domain = ".s3.garage.localhost"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.localhost"

[admin]
api_bind_addr = "0.0.0.0:3903"
admin_token = "$ADMIN_TOKEN"
EOF

# 3. Création du compose.yml
cat <<EOF > compose.yml
services:
  garage:
    image: dxflrs/garage:v1.0.1
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

echo "✅ Configuration terminée."
echo "🔑 Admin Token : $ADMIN_TOKEN"
echo "🚀 Pour démarrer : docker compose up -d"
echo "⚙️  Ensuite, configurez le layout :"
echo "   docker exec -it garage /garage layout assign --zone dc1 --capacity 10G \$(docker exec garage /garage node id | cut -d'@' -f1)"
echo "   docker exec -it garage /garage layout apply --version 1"



