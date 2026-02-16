# Security Practices

## Critical: Secrets Management

### Never commit secrets to git
The `.gitignore` excludes `.env` which contains your API keys and tokens. Never bypass this.

### Rotate credentials regularly
- **Anthropic API key**: Rotate at https://console.anthropic.com — regenerate and update `.env`
- **Discord bot token**: Rotate at https://discord.com/developers — reset token and update `.env`
- **Gateway token**: Regenerate with `openssl rand -hex 32` and update `.env`
- After rotating any secret: `sudo docker-compose up -d openclaw` to apply

### Never share credentials in chat
Passwords, API keys, and tokens shared in plain text (chat, email, Slack) should be considered compromised. Rotate them immediately after any accidental exposure.

## Access Control

### Discord (who can use the bot)

The bot is locked to your Discord user ID (`306651957458763778`) via:

- `allowFrom`: Only your user ID can interact with the bot
- `dmPolicy: pairing`: Unknown users must be manually approved
- `groupPolicy: allowlist`: The bot ignores servers unless explicitly allowed

To approve a new DM sender:
```bash
sudo docker exec openclaw node dist/index.js pairing list --channel discord
sudo docker exec openclaw node dist/index.js pairing approve discord <code>
```

### Dashboard (Control UI)

- Accessible only via HTTPS (`https://192.168.1.106:18790`)
- Requires gateway token in the URL hash
- `allowedOrigins` restricts which domains can connect
- `trustedProxies` is scoped to your Docker and LAN subnets

### Gateway

- `auth.mode: token` — all connections require the gateway token
- The gateway binds to `0.0.0.0` inside the container but nginx terminates TLS in front of it
- Port 18789 is exposed on the LAN — restrict via Synology firewall if needed

## Network Security

### Current setup
- Dashboard exposed on LAN via nginx reverse proxy with TLS (port 18790)
- Gateway port 18789 also exposed on LAN (used by nginx proxy)
- No ports forwarded to the public internet

### Recommendations
1. **Synology Firewall**: Restrict port 18789 and 18790 to your trusted devices only
   - DSM > Control Panel > Security > Firewall
   - Allow only your device IPs to ports 18789, 18790
   - Deny all other inbound traffic to those ports

2. **Remote access**: Use Tailscale instead of port forwarding
   - The `docker-compose.yml` includes a Tailscale sidecar — configure it when ready
   - Never expose the gateway directly to the internet

3. **NAS SSH**: Consider disabling SSH when not actively needed, or restrict it to key-based auth only

## What the Bot Can Do (Attack Surface)

OpenClaw is powerful — understand what it has access to:

| Capability | Risk | Mitigation |
|---|---|---|
| Shell commands | Can run anything as the container user | Container isolation limits blast radius |
| File system | Read/write to mounted volumes | Only `/volume1/docker/openclaw/` is mounted |
| Browser | Can browse the web via headless Chrome | Don't store browser sessions with logged-in accounts |
| Discord | Can read/send messages as the bot | `allowFrom` restricts who can trigger it |
| API keys | Has access to your Anthropic key | Container env vars, not on disk outside `.env` |

### Sandboxing (optional, recommended)

For additional isolation, enable OpenClaw's sandbox mode in `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "scope": "agent",
        "docker": {
          "network": "none",
          "memory": "1g"
        }
      }
    }
  }
}
```

This runs agent tool calls in isolated containers with no network access.

### Elevated mode

- `/elevated on` in a chat session grants the bot unrestricted bash access
- **Never leave elevated mode on** — always `/elevated off` when done
- Default is off

## Monitoring

### Check for suspicious activity
```bash
# Recent gateway connections
sudo docker logs openclaw 2>&1 | grep '\[ws\]'

# Who connected recently
sudo docker logs openclaw 2>&1 | grep 'webchat connected\|closed'

# Discord interactions
sudo docker logs openclaw 2>&1 | grep '\[discord\]'
```

### Update regularly
```bash
# Check for updates
sudo docker exec openclaw node dist/index.js update --check

# Apply updates
sudo docker pull alpine/openclaw:latest
sudo docker-compose up -d openclaw
```

## Incident Response

If you suspect your bot has been compromised:

1. **Stop the container immediately**: `sudo docker-compose down`
2. **Rotate all credentials**: Anthropic key, Discord token, gateway token
3. **Check logs**: Look for unexpected connections or commands
4. **Review workspace**: Check `/volume1/docker/openclaw/workspace/` for unexpected files
5. **Restart with fresh config**: Update `.env` with new credentials, `sudo docker-compose up -d`
