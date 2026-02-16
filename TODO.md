# Setup To-Do Items

Step-by-step guides for the remaining hardening tasks.

---

## 1. Set Up Tailscale for Remote Access

Tailscale gives you secure access to the OpenClaw dashboard from anywhere without exposing ports to the internet.

### Prerequisites
- A Tailscale account (free at https://tailscale.com)
- Tailscale installed on your phone/laptop (the device you'll access from)

### Steps

1. **Generate an auth key** at https://login.tailscale.com/admin/settings/keys
   - Click "Generate auth key"
   - Check **Reusable** (so the container can reconnect after restarts)
   - Check **Ephemeral** (node auto-removes when offline for 30+ min)
   - Copy the key — it starts with `tskey-auth-`

2. **Add the key to your `.env`** on the NAS:
   ```bash
   ssh dannytaki@192.168.1.106
   nano /volume1/docker/openclaw/.env
   ```
   Replace the placeholder:
   ```
   TS_AUTHKEY=tskey-auth-your-actual-key-here
   ```

3. **Start the Tailscale sidecar**:
   ```bash
   export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH
   cd /volume1/docker/openclaw
   sudo docker-compose up -d tailscale
   ```

4. **Verify it connected**:
   ```bash
   sudo docker logs openclaw-tailscale --tail 20
   ```
   You should see a line like `Success` or the Tailscale IP.

5. **Find the Tailscale hostname**:
   - Go to https://login.tailscale.com/admin/machines
   - Look for `openclaw-nas` — note its Tailscale IP (e.g., `100.x.y.z`)

6. **Access the dashboard remotely**:
   - From any device on your Tailnet: `https://openclaw-nas.<your-tailnet>.ts.net/#token=<gateway-token>`
   - Tailscale Serve handles TLS automatically — no self-signed cert warnings

### Updating the auth key
Auth keys expire. When the Tailscale container stops connecting:
1. Generate a new key at https://login.tailscale.com/admin/settings/keys
2. Update `TS_AUTHKEY` in `.env`
3. `sudo docker-compose up -d tailscale`

---

## 2. Rotate Credentials

Rotate these periodically or immediately after any accidental exposure.

### Anthropic API Key

1. Go to https://console.anthropic.com/settings/keys
2. Click "Create Key" to generate a new one
3. Copy the new key (starts with `sk-ant-`)
4. Update on the NAS:
   ```bash
   ssh dannytaki@192.168.1.106
   nano /volume1/docker/openclaw/.env
   ```
   Replace the `ANTHROPIC_API_KEY=` line with your new key
5. Apply the change:
   ```bash
   export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH
   cd /volume1/docker/openclaw
   sudo docker-compose up -d openclaw
   ```
6. Go back to https://console.anthropic.com/settings/keys and **delete the old key**

### Discord Bot Token

1. Go to https://discord.com/developers/applications
2. Select "clawbot" > Bot
3. Click "Reset Token" and confirm
4. Copy the new token
5. Update `DISCORD_BOT_TOKEN=` in `/volume1/docker/openclaw/.env`
6. Apply:
   ```bash
   cd /volume1/docker/openclaw
   sudo docker-compose up -d openclaw
   ```

### Gateway Token

1. Generate a new token:
   ```bash
   openssl rand -hex 32
   ```
2. Update `OPENCLAW_GATEWAY_TOKEN=` in `/volume1/docker/openclaw/.env`
3. Apply:
   ```bash
   cd /volume1/docker/openclaw
   sudo docker-compose up -d openclaw
   ```
4. Update your bookmarked dashboard URL with the new token in the `#token=` hash

### NAS Password

1. Log in to DSM at http://192.168.1.106:5000
2. Click your profile icon (top right) > Personal > Change Password
3. Set a strong password (16+ characters, mixed case, numbers, symbols)
4. Update your SSH client / password manager with the new password

---

## 3. Set Up Synology Firewall Rules

Restrict gateway and dashboard ports so only your trusted devices can connect.

### Steps

1. **Log in to DSM** at http://192.168.1.106:5000

2. **Open the firewall settings**:
   - Control Panel > Security > Firewall
   - Check "Enable firewall" if not already enabled
   - Click "Edit Rules" on the default profile

3. **Create an allow rule for your devices**:
   - Click "Create"
   - Ports: Select "Custom", enter `18789, 18790`
   - Source IP: Select "Specific IP" > "Single host" or "IP range"
     - Add your PC's IP (e.g., `192.168.1.x`)
     - Add your phone's IP if applicable
     - Add the Docker bridge subnet: `172.18.0.0/16`
   - Action: **Allow**
   - Click OK

4. **Create a deny rule for everyone else**:
   - Click "Create"
   - Ports: Select "Custom", enter `18789, 18790`
   - Source IP: Select "All"
   - Action: **Deny**
   - Click OK

5. **Verify rule order**:
   - The Allow rule must be **above** the Deny rule (rules are evaluated top to bottom)
   - Drag to reorder if needed

6. **Apply**:
   - Click OK to save
   - Test that you can still access the dashboard from your PC
   - Test that the bot still works in Discord (it connects outbound, not affected by inbound rules)

### Important notes
- If your PC gets a new IP from DHCP, you'll be locked out. Consider setting a static IP or using an IP range (e.g., `192.168.1.100-192.168.1.110`)
- The Docker bridge subnet (`172.18.0.0/16`) must be allowed so containers can communicate internally
- These rules only affect LAN access. If you set up Tailscale, Tailscale traffic bypasses the NAS firewall (it's encrypted end-to-end)
