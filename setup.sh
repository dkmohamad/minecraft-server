#!/bin/bash
# First-time setup: copy config templates into data dirs and generate .env
set -e

# Copy configs (cp -n = no-clobber, safe to re-run)
cp -n conf/server.properties data/minecraft/server.properties
cp -n conf/geyser.yml        data/geyser/config.yml
cp -n conf/viaproxy.yml      data/viaproxy/viaproxy.yml

# Generate .env with random RCON password if it doesn't exist
if [ ! -f .env ]; then
  RCON_PASS=$(openssl rand -hex 16)
  echo "RCON_PASSWORD=$RCON_PASS" > .env
  echo "Generated .env with RCON_PASSWORD"
else
  echo ".env already exists, skipping"
fi

echo "Done. Run: docker compose up -d"
