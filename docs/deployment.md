# Deployment

How this stack is deployed, how versions are pinned, and how to update or roll back. For
troubleshooting connection issues see [troubleshooting.md](troubleshooting.md); for the
design history see [decision-log.md](decision-log.md).

## What's deployed

Four Docker Compose services (`docker-compose.yml`):

| Service    | Image / build              | Role |
|------------|----------------------------|------|
| `mc`       | `itzg/minecraft-server`    | Vanilla MC server (`VERSION=26.1`, online-mode off), the world's native version |
| `viaproxy` | `ghcr.io/viaversion/viaproxy` | Java protocol translation (client ↔ MC 26.1) |
| `geyser`   | built from `geyser.Dockerfile` | Bedrock ↔ Java bridge, UDP 19132 |
| `backup`   | `itzg/mc-backup`           | Daily world backups, 7 retained |

**The exact pinned versions ARE the docker files** — `docker-compose.yml` (`@sha256` image
digests + `pull_policy: never`) and `geyser.Dockerfile` (explicit Geyser version/build). Those
files are the single source of truth; this doc records *policy and history*, not a second copy
of the digests.

## Version-pinning policy

This is a fragile version chain (`Bedrock → Geyser → ViaProxy → MC`); an unattended
`:latest`/daily pull of any link can silently break cross-play. Rules:

1. **Pin everything.** Every service uses `image: …@sha256:<digest>` + `pull_policy: never`;
   Geyser is pinned to an explicit `versions/<v>/builds/<n>` URL (never
   `versions/latest/builds/latest`).
2. **Pinning ≠ freeze forever — track the latest *released* Minecraft.** Bedrock and Java
   clients auto-update; the server side must keep pace or new clients are rejected ("Outdated
   Geyser proxy"). Bump the **bridge** (Geyser + ViaProxy) to follow releases.
3. **Keep MC + the world at the world's native version** (currently `26.1`). The bridge
   translates newer clients *down* to it. Only bump `VERSION` to deliberately upgrade the
   world format.
4. **Every pin change is deliberate:** bump → reconnect-test (one Bedrock + one Java at the
   same time) → capture the new digest/build → update the docker file(s) → add a change-log
   entry below. Never leave an image floating on `:latest` after testing.

## Runbook

### Deploy / start
```bash
docker compose up -d          # uses on-disk pinned images; no pull
docker compose ps             # all four Up; mc shows (healthy)
docker compose exec mc rcon-cli list      # who's online
```

### Update a component (deliberate bump)
```bash
# ViaProxy: temporarily set its image back to :latest, then
docker compose pull viaproxy
docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/viaversion/viaproxy:latest   # re-pin this digest
docker compose up -d viaproxy
docker compose logs viaproxy | grep -i 'highest supported'   # confirm it covers the client version

# Geyser: edit the build number in geyser.Dockerfile, then
docker compose build geyser && docker compose up -d geyser
```
Then reconnect-test (Bedrock + Java) and record the change below.

### Roll back
Revert the pin(s) in `docker-compose.yml` / `geyser.Dockerfile` to the previous digest/build
(see change log) and `docker compose up -d`. Prior images stay cached locally, so rollback is
offline and instant.

## Change log

### 2026-06-20 — initial cloud-free deploy + froze versions, then bumped the bridge for client drift
- Started the stack from on-disk images (no pulls) and **pinned all four services by digest**
  (`pull_policy: never`); pinned Geyser build in `geyser.Dockerfile`.
- Party clients had auto-updated past the original bridge: iPad **Bedrock 26.21** got "Outdated
  Geyser proxy" (Geyser `2.9.5-b1107` topped out at Bedrock 26.10); Linux **Java 26.2** exceeded
  ViaProxy's max of 26.1 (775).
- **Bumped the translation layer only**, keeping MC + world native at 26.1:
  - Geyser `2.9.5-b1107` → **`2.10.1-b1172`** (now supports Bedrock 26.21).
  - ViaProxy → digest pinned in `docker-compose.yml` (now reports **highest supported 26.2 / 776**).
- **Verified:** iPad Bedrock 26.21 joined the live world (player `ThunderMo3000`) and the world
  was visible from Xbox. Java path not tested (not needed for this event).
- **Previous pins for rollback:** Geyser `2.9.5/1107`; ViaProxy
  `@sha256:08524ce0b4c82d8c7fcfad7f5a2d9f6eda7508396f84a68deb9c71b3e1d88530` (both still cached).
