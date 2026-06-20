# CLAUDE.md

Guidance for working in this repo. See `README.md` for the docs index, `docs/deployment.md`
for versions + deploy/rollback, and `docs/decision-log.md` for the dev/decision log.

## What this is
A Vanilla Minecraft server with Bedrock crossplay, run via Docker Compose:
`Bedrock client → Geyser (19132/udp) → ViaProxy (25568/tcp) → MC (25565/tcp)`, plus an
`itzg/mc-backup` sidecar. Config templates live in `conf/`; runtime data (worlds, plugins,
generated configs, backups) lives in gitignored `data/`.

**The exact pinned versions ARE the docker files** (`docker-compose.yml` digests +
`geyser.Dockerfile` build) — the single source of truth. Don't restate version numbers in prose
docs; they go stale. Deploy history is in `docs/deployment.md`.

## Rules

### Pin Docker images by digest — never run `:latest` unattended
This is a fragile version chain; an auto-pull of any link can silently break crossplay.
- Every service in `docker-compose.yml` MUST use `image: …@sha256:<digest>` + `pull_policy: never`.
- Geyser is built locally; pin its build to an explicit `versions/<v>/builds/<n>` URL in
  `geyser.Dockerfile` (never `versions/latest/builds/latest`).
- Changing a pin is a deliberate act: **bump → reconnect-test (one Bedrock + one Java at the
  same time) → capture the new digest/build → update the pin in the docker file → add a
  `docs/deployment.md` change-log entry.** Never leave an image floating after a test.

### Pinning ≠ freeze forever — track the released Minecraft version
Pinning prevents *unattended* drift; it does **not** mean the versions are static. Bedrock and
Java clients auto-update to the latest released Minecraft, and the server-side chain must keep
pace or new clients get rejected (e.g. "Outdated Geyser proxy"). So:
- The **bridge** (Geyser + ViaProxy) must be bumped to keep up with the **latest released
  Minecraft**; re-pin to the new working build whenever clients move ahead.
- The **MC server stays at the world's native version** (the version the save was created in;
  current value in `docker-compose.yml` `VERSION`) and the bridge translates newer clients
  *down* to it. Only bump the MC version itself if you intend to upgrade the world format.

### Don't pull/rebuild "to be safe"
Prefer the on-disk images. Only pull or `build` when a specific component is proven broken
(e.g. an "Outdated Geyser proxy" rejection). The old pinned images are the rollback path.

### Protect the world data
`data/` is gitignored and holds the real save(s). Stop `mc` before copying/moving world
folders so the copy is consistent. Never overwrite `data/minecraft/world` blindly.

## Handy commands
```bash
docker compose ps
docker compose logs -f mc viaproxy geyser
docker compose exec mc rcon-cli list          # who's online
docker compose exec mc rcon-cli version       # MC build + protocol
```
