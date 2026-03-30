# Truest Survivor Minecraft Server

Vanilla 26.1 Minecraft server with Bedrock cross-play via Geyser + ViaProxy, running in Docker; this admits players on bedrock and standard java versions of minecraft and allows them to play together.

## Architecture

```
iPad (Bedrock) → Geyser (19132/udp) → ViaProxy (25568/tcp) → MC Server (25565/tcp)
```

- **MC Server** — Vanilla 26.1 via `itzg/minecraft-server`
- **ViaProxy** — Translates Java 1.21.11 ↔ 26.1 protocol
- **Geyser** — Translates Bedrock ↔ Java Edition
- **Backup** — Daily automated backups via `itzg/mc-backup`

## Setup

```bash
git clone <repo-url> && cd minecraft-server

# Run first-time setup (copies configs, generates RCON password)
./setup.sh

# Copy your world into the server data directory (optional)
cp -r /path/to/your/world data/minecraft/world

# Start all containers
docker compose up -d
```

`setup.sh` copies the config templates from `conf/` into `data/` subdirectories and generates a `.env` file with a random RCON password. It uses `cp -n` (no-clobber) so it's safe to re-run without overwriting existing configs.

## Directory Structure

```
conf/                  # Version-controlled config templates
  server.properties    # MC server config (MOTD, online-mode, RCON)
  geyser.yml           # Geyser config (upstream address, auth, MOTD)
  viaproxy.yml         # ViaProxy config (bind, target, online-mode)
data/                  # Runtime data (gitignored)
  minecraft/           # MC server data, world, logs
  geyser/              # Geyser runtime data
  viaproxy/            # ViaProxy runtime data
  backups/             # Automated backups
```

## Backups

- Automatic daily backups via `itzg/mc-backup`
- 7 most recent backups retained
- Stored in `data/backups/`
- Uses RCON to safely pause world saving during backup

## Ports

| Service  | Port        | Protocol |
|----------|-------------|----------|
| MC       | 25565       | TCP      |
| ViaProxy | 25568       | TCP      |
| Geyser   | 19132       | UDP      |
