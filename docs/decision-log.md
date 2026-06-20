# Truest Survivor Minecraft Server — Notes & Decision Log

## Quick Reference
- **Server**: Vanilla 26.1 in Docker (`itzg/minecraft-server`)
- **World**: Original "Truest Survivor" from `~/Documents/.minecraft/saves/`
- **Dev machine**: `192.168.1.252` (Ethernet `enp10s0`, DHCP, gateway 192.168.1.254 — Plusnet Hub)
- **iPad**: Bedrock v26.10, IP varies
- **Ports**: MC 25565/tcp, ViaProxy 25568/tcp, Geyser 19132/udp

---

> **Version pins and deploy/rollback procedures live in [deployment.md](deployment.md).** This
> file is the dev/decision log — what was tried, ruled out, and why.

---

## Decision Log

### D1: World conversion abandoned — run server at native version
- **Problem**: Truest Survivor world is version 26.1, need multiplayer server
- **Tried**: Chunker CLI downgrade to 1.21.11 — Nether broke (contents displaced)
- **Decision**: Run server at 26.1 to match world natively, no conversion
- **Result**: Working. World loads with all 3 dimensions intact

### D2: Vanilla instead of Paper
- **Problem**: Paper 26.1 not available in itzg docker image (tried both `1.26` and `26.1`)
- **Note**: Minecraft changed versioning in 2026 to `year.drop.hotfix` — version is `26.1` not `1.26`
- **Decision**: Use `TYPE: "VANILLA"` with `VERSION: "26.1"`
- **Trade-off**: No plugin support (no ViaVersion, no Floodgate, no Geyser-as-plugin)
- **Result**: Working. Server starts, world loads fine

### D3: Geyser standalone + ViaProxy for Bedrock crossplay
- **Problem**: Geyser emulates Java 1.21.11 client, server is 26.1 — protocol mismatch. Can't use ViaVersion plugin (vanilla server)
- **Decision**: 3-container architecture:
  ```
  iPad (Bedrock 26.10) → Geyser (19132/udp) → ViaProxy (25568/tcp) → MC (25565/tcp)
  ```
  - Geyser translates Bedrock → Java 1.21.11
  - ViaProxy translates Java 1.21.11 → 26.1
- **Result**: All 3 containers start and run. Internal connectivity verified (Geyser→ViaProxy→MC all reachable). Not yet confirmed with actual player login.

### D4: UDP blocked between Wi-Fi and Ethernet — connect dev machine to Wi-Fi
- **Problem**: iPad (Wi-Fi) couldn't reach dev machine (Ethernet) on UDP port 19132
- **Investigation**:
  - `ping dev→iPad`: OK
  - `tcpdump TCP iPad→dev:25565`: Packets arrive, full handshake
  - `tcpdump UDP iPad→dev:19132`: **Zero packets** — router drops UDP between Wi-Fi and Ethernet
  - Plusnet Hub router has no exposed AP isolation or UDP filtering settings
- **Decision**: Connect dev machine to Wi-Fi in addition to Ethernet, use Wi-Fi IP (<dev-machine-wifi-ip>)
- **Result**: U000 error gone. iPad now reaches Geyser (pings visible in logs). iPad got new IP (.88) on shared Wi-Fi
- **UPDATE**: The Ethernet IP actually works too — iPad connects to `<dev-machine-ip>:19132` successfully. Connecting the dev machine to Wi-Fi may have fixed the router's ARP/routing table so UDP now flows between iPad and Ethernet interface. The Linux routing table prefers Ethernet (metric 100) over Wi-Fi (metric 600) for the LAN subnet, so all traffic goes via `enp10s0` regardless. May not need Wi-Fi on dev machine at all — needs more testing.

### D5: Geyser host networking — didn't work
- **Problem**: iPad could ping Geyser but "tried to connect" never progressed — suspected Docker NAT/RakNet issue
- **Tried**: `network_mode: host` on Geyser container
- **Result**: Failed. Geyser claimed to bind port 19132 but `ss -ulnp` showed nothing on that port. Port wasn't actually bound. Back to U000 error.
- **Decision**: Reverted to Docker port-mapped Geyser. Host networking not viable for Geyser in Docker.

### D6: "Tried to connect" / U000 on server list — RESOLVED
- **Problem**: iPad showed U000 error on server list page and "tried to connect" in debug logs
- **Root cause**: The U000 and "tried to connect" messages were misleading — they appear on the **server list browsing screen**, not when actually joining. Geyser's ping passthrough to ViaProxy fails (ViaProxy doesn't respond to legacy MC ping protocol), so the server list shows an error.
- **Fix**: Disabled `passthrough-motd` and `passthrough-player-counts` in Geyser config. Server still shows in list as "Truest Survivor". Tapping **Join Server** works.
- **Result**: WORKING. Full connection chain confirmed:
  - Geyser: `<player-1>` connected, skin loaded, spawned at (26.5, 70.0, -6.5)
  - ViaProxy: `[1.21.11 <-> 26.1]` protocol translation successful
  - MC Server: `<player-1> joined the game`

### D7: Multiple accounts working — RESOLVED
- **Problem**: Daughter's Xbox profile showed "trouble establishing connection to multiplayer services"
- **Root cause**: Server address was set to hostname instead of IP. Bedrock client can't resolve local hostnames.
- **Fix**: Use IP address (not hostname) when adding server on Bedrock clients
- **Result**: Both accounts (<player-1> + daughter's profile) can connect simultaneously

### D8: Clients auto-updated past the bridge — bumped Geyser + ViaProxy (2026-06-20)
- **Problem**: Party-day clients had updated ahead of the original bridge. iPad **Bedrock 26.21**
  was rejected with *"Outdated Geyser proxy! This server supports … 26.10"* (Geyser `2.9.5-b1107`
  topped out at Bedrock 26.10); the Linux **Java 26.2** client exceeded ViaProxy's max of 26.1 (775).
- **Ruled out**: upgrading MC / the world to chase the clients (forces a world-format upgrade,
  risks the save) and downgrading clients (Bedrock auto-updates, can't easily pin).
- **Decision**: update ONLY the translation layer, keep MC + world native at 26.1.
  - Geyser `2.9.5-b1107` → `2.10.1-b1172` — adds Bedrock 26.21.
  - ViaProxy → newer pinned digest — now reports highest supported 26.2 (776).
  - Side effect: the new Geyser emulates Java 26.1 (not 1.21.11), so the chain is now almost
    native (`[26.1 <-> 26.1]` in ViaProxy logs).
- **Result**: WORKING. iPad Bedrock 26.21 joined the live world (`ThunderMo3000`); world visible
  from Xbox. Java path not tested (not needed for this event).
- Current pins: `docker-compose.yml` / `geyser.Dockerfile`. Deploy history: [deployment.md](deployment.md).

---

## Technical Gotchas Reference

### Docker / Geyser
- **Don't bind-mount config.yml as a single file** — Geyser uses atomic file replace, fails with "Device or resource busy" on bind-mounted files
- **Geyser jar and data must be in separate dirs** — mounting a volume over the jar directory hides it
- **Geyser `network_mode: host` doesn't work** — claims to bind port but doesn't actually appear in `ss -ulnp`

### Docker / ViaProxy
- **Must override entrypoint for CLI mode** — ViaProxy docker image ignores `command`, needs: `entrypoint: ["java", "-jar", "/app/ViaProxy.jar", "cli"]`
- **Startup timing** — ViaProxy logs "Could not connect to backend server" if MC isn't ready. Transient, resolves once MC is up

### Network / Plusnet Hub
- **UDP dropped between Wi-Fi and Ethernet** — router does not forward UDP from wireless to wired clients. TCP works fine. No user-facing setting to fix this
- **Workaround**: Both devices must be on the same interface (both Wi-Fi, or both Ethernet)
- **iPad IP changes** when switching Wi-Fi networks — check with Settings → Wi-Fi → (i) icon

### Minecraft Versioning
- 2026 uses `year.drop.hotfix` format: version is `26.1`, not `1.26`
- Docker `VERSION` env var must be `"26.1"`
- Paper/Fabric availability lags behind vanilla for new version format
