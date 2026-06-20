# Truest Survivor Minecraft Server

Vanilla Minecraft server (currently 26.1) with Bedrock cross-play via Geyser + ViaProxy,
running in Docker. Players on Bedrock (Xbox, iPad/tablet, phone, Windows) and Java Edition all
connect to the same world.

## Architecture

```
Bedrock client → Geyser (19132/udp) → ViaProxy (25568/tcp) → MC Server (25565/tcp)
```

- **MC Server** — Vanilla Minecraft via `itzg/minecraft-server` (kept at the world's native version)
- **ViaProxy** — translates between the client's Java protocol and the MC server version
- **Geyser** — translates Bedrock ↔ Java Edition
- **Backup** — daily automated backups via `itzg/mc-backup`

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
docs/                  # Project documentation (see below)
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

## Documentation

- **[docs/deployment.md](docs/deployment.md)** — how the stack is deployed, the version-pinning
  policy, the deploy / update / rollback runbook, and a dated change log.
- **[docs/troubleshooting.md](docs/troubleshooting.md)** — common connection problems and fixes
  (client version drift, Microsoft account permissions, UDP/network).
- **[docs/decision-log.md](docs/decision-log.md)** — dev/decision log: what was tried, ruled out,
  and why (D1–D8) + technical gotchas.
- **[CLAUDE.md](CLAUDE.md)** — working rules for this repo.

> **Versions are pinned.** The exact pins are the docker files themselves — `docker-compose.yml`
> (`@sha256` image digests) and `geyser.Dockerfile` (Geyser build). They are the source of
> truth; read `docs/deployment.md` before changing them.
