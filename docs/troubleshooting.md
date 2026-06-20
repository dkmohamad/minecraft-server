# Troubleshooting

Common connection problems and fixes. For the *why* behind the design, see
[decision-log.md](decision-log.md); for version/pinning procedures see
[deployment.md](deployment.md).

## "Outdated Geyser proxy" — Bedrock client can't join after an app update

Bedrock auto-updates (App Store / console / Game Pass). When the client's Bedrock version is
newer than what the running Geyser build supports, the join is refused and Geyser logs:
`Outdated Geyser proxy! This server supports the following Bedrock versions: …`. The listed
versions tell you how far behind Geyser is.

**Fix:** bump the Geyser build in `geyser.Dockerfile` to one that lists the client's version,
`docker compose build geyser && docker compose up -d geyser`, then re-pin (see
[deployment.md](deployment.md)). Keep MC + the world at their native version — only the
translation layer moves.

## Java client newer than the server ("Outdated server" / can't connect to :25565)

The Java client must not be newer than the bridge. Two options:

- Point the Java client at **ViaProxy** (`<host>:25568`) instead of MC directly (`:25565`);
  ViaProxy must report `Highest supported version ≥ <client version>` in its startup log
  (bump ViaProxy if not).
- Or select the matching server version in the Java launcher and connect directly to `:25565`.

## Bedrock device prompts to sign in / "can't join multiplayer"

Even though the server is `online-mode=false`, the Bedrock **client** still enforces Microsoft
rules: the device must be signed into Xbox Live, and the account needs **"Join multiplayer
games"** enabled (child accounts: toggle at family.microsoft.com → child → Privacy/Xbox).
Test every account that will be used *before* the day. The U000/error icon on the server-list
screen is cosmetic (passthrough-motd is disabled) — tapping **Join Server** still works.

## Bedrock can't reach the server over Wi-Fi (UDP)

Historically the Plusnet Hub dropped UDP between Wi-Fi and Ethernet (decision-log.md D4). If a
Bedrock device pings but never joins, check `docker compose logs geyser | grep -i connect`
and test with the device on the same interface as the server. Use the server's **IP**
(`192.168.1.252`), not a hostname — Bedrock can't resolve LAN hostnames.
