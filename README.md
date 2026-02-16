# OpenClaw on Synology NAS (DS920+)

Self-hosted AI assistant running on a Synology DS920+ NAS with Discord integration and secure remote access.

## Architecture

```
Browser (LAN)                Discord DM
    │                            │
    ▼                            ▼
nginx reverse proxy         Discord API
(HTTPS :18790)                   │
    │                            ▼
    └──────► OpenClaw Gateway ◄──┘
             (ws :18789)
             Docker container
             /volume1/docker/openclaw/
```

## Quick Reference

| Service | URL |
|---|---|
| Dashboard | `https://192.168.1.106:18790/#token=<gateway-token>` |
| Gateway (internal) | `ws://127.0.0.1:18789` |
| DSM | `http://192.168.1.106:5000` |

## File Locations

| Path | Purpose |
|---|---|
| `/volume1/docker/openclaw/docker-compose.yml` | Container configuration |
| `/volume1/docker/openclaw/.env` | Secrets (API keys, tokens) |
| `/volume1/docker/openclaw/config/openclaw.json` | OpenClaw runtime config |
| `/volume1/docker/openclaw/workspace/` | Agent workspace files |
| `/usr/local/etc/nginx/sites-enabled/openclaw.conf` | Nginx reverse proxy |

## Common Operations

### Start / Stop / Restart

```bash
ssh dannytaki@192.168.1.106
export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH
cd /volume1/docker/openclaw

# Restart (picks up openclaw.json changes)
sudo docker restart openclaw

# Recreate (picks up .env changes)
sudo docker-compose up -d openclaw

# Stop
sudo docker-compose down

# View logs
sudo docker logs openclaw --tail 50
sudo docker logs -f openclaw  # follow live
```

### Update OpenClaw

```bash
sudo docker pull alpine/openclaw:latest
sudo docker-compose up -d openclaw
```

### Check Health

```bash
sudo docker ps                          # container status
sudo docker exec openclaw node dist/index.js doctor  # config check
```

## Configuration

Runtime config lives in `/volume1/docker/openclaw/config/openclaw.json`. The gateway watches this file and hot-reloads most changes without a restart.

Secrets live in `/volume1/docker/openclaw/.env` — changes require a `docker-compose up -d` (not just restart).
