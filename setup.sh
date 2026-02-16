#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Synology NAS Setup Script
# Run this on your NAS via SSH

echo "=== OpenClaw Synology Setup ==="

# 1. Create persistent directories
echo "[1/4] Creating directories on /volume1..."
sudo mkdir -p /volume1/docker/openclaw/config
sudo mkdir -p /volume1/docker/openclaw/workspace
sudo chown -R 1000:1000 /volume1/docker/openclaw

# 2. Create .env from template if it doesn't exist
if [ ! -f .env ]; then
    echo "[2/4] Creating .env from template..."
    cp .env.example .env
    # Generate a random gateway token
    RANDOM_TOKEN=$(openssl rand -hex 32)
    sed -i "s/change-me-to-a-random-token/${RANDOM_TOKEN}/" .env
    echo "       Generated gateway token."
    echo "       IMPORTANT: Edit .env and fill in your API keys before starting!"
else
    echo "[2/4] .env already exists, skipping."
fi

# 3. Run onboarding
echo "[3/4] Running OpenClaw onboarding..."
docker compose run --rm openclaw onboard

# 4. Start services
echo "[4/4] Starting OpenClaw..."
docker compose up -d

echo ""
echo "=== Setup Complete ==="
echo "Dashboard: http://$(hostname -I | awk '{print $1}'):18789"
echo "Run 'docker compose logs -f openclaw' to watch logs."
echo ""
echo "Next steps:"
echo "  1. Open the dashboard and enter your gateway token"
echo "  2. Approve your Discord bot pairing with:"
echo "     docker exec openclaw node dist/index.js pairing list"
echo "     docker exec openclaw node dist/index.js pairing approve <channel> <code>"
