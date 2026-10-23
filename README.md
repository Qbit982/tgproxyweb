# Telegram WEB Proxy + 2048 — Docker / Podman

Dedicated Linux x86_64 VPS; original `telegramdesktop/tproxy-server`, official MTProxy,
Caddy with automatic HTTPS, and the authentic 2048 web game by Gabriele Cirulli (MIT).

## Architecture

`Internet :443 -> Caddy -> tproxy-server (127.0.0.1:8080) -> 2048 or local MTProxy (127.0.0.1:2398)`

The three runtime containers share the Caddy network namespace. The game is served **by
tproxy-server**, not by a separate `file_server` branch in Caddy. No admin or backend port
is published. This deployment defaults to the `https` carrier mode.

## Prerequisites

- Docker Engine with Compose v2, or Podman with a [Compose provider](https://docs.podman.io/en/latest/markdown/podman-compose.1.html).
- `git`, Linux x86_64, SSH access.
- A dedicated lowercase DNS name (A record pointing to the VPS). Remove broken AAAA records.
- Open inbound **TCP 443** in provider firewall, keep SSH working.
- Port 443 on the host must be free; do not run a second Caddy/Nginx on this port.
- Disable reverse proxy/CDN (e.g. Cloudflare orange cloud) for first deployment.

## Quickstart

```sh
unzip tproxy-2048-compose.zip
cd tproxy-2048-compose
./scripts/init.sh
nano .env                  # change DOMAIN and ACME_EMAIL
cat .env                   # review pinned TPROXY_COMMIT

./scripts/compose.sh config -q
./scripts/compose.sh up -d --build
./scripts/compose.sh ps
```

`compose.sh` selects Docker Compose when available, otherwise Podman Compose.
To choose explicitly, run `export CONTAINER_ENGINE=docker` or
`export CONTAINER_ENGINE=podman` before running the scripts. Keep the same engine
and OS user for all commands: their containers and volumes are separate.
On Linux, Podman needs root privileges or rootless access to host port 443.

Caddy obtains and renews certificates using [TLS-ALPN-01](https://caddyserver.com/docs/automatic-https#tls-alpn-challenge)
on TCP 443. HTTP redirects and the HTTP certificate challenge are disabled; port 80 is unused.

`init.sh` fetches the original 2048 into `site/`, pins a concrete upstream relay commit,
and writes it to `.env`. The one-shot `secrets-init` service generates (only once) a random
client proxy secret and a persistent private 32-byte token signing key in the named
`state` volume; it gives their files restrictive permissions and separate runtime UIDs.
The `mtproxy-init` job downloads official Telegram backend routing material.

**First start:** the container engine builds the relay from the pinned official commit and the MTProxy
from its pinned commit with a SHA-256-checked archive. It needs outbound HTTPS and CPU.

## Connect Telegram

```sh
./scripts/output.sh
```

The script prints the server, secret, and a `tg://webproxy` connection link on its own line for copying.

In a Telegram app that supports **WEB** proxy, set `Server` to the printed hostname and
`Secret` to the 32-character lowercase hex string. The server has **no** `https://`,
port or query. WEB transport connects via HTTPS port 443.

Open `https://YOUR_DOMAIN/` to see the real 2048 game.

## Checks

```sh
curl -I https://YOUR_DOMAIN/
curl -I https://YOUR_DOMAIN/js/application.js
./scripts/compose.sh ps
./scripts/compose.sh logs --tail 100 relay mtproxy caddy
```

From outside the VPS, only TCP 443 (and deliberately open SSH) should be accessible.
Do not forward/publish TCP 2398, 8888, 8080 or 8081. If Caddy cannot get TLS, check DNS,
port 443 and lack of a conflicting web server.

## Updates, site changes and backup

```sh
# Rebuild at the same pinned source commit:
./scripts/compose.sh build --pull
./scripts/compose.sh up -d

# Refresh routing data manually:
./scripts/compose.sh run --rm mtproxy-init
./scripts/compose.sh restart mtproxy

# Replace the game/site; restart relay because it caches static site in memory:
./scripts/site.sh
./scripts/compose.sh restart relay

# Stop without deleting certificates and keys:
./scripts/compose.sh down
```

For a new relay commit, review source changes first, replace `TPROXY_COMMIT` in `.env`,
then rebuild and restart the relay. **Never run `./scripts/compose.sh down -v` casually**:
that removes the persistent signing key and proxy secret as well as Caddy certificates.
Back up the named volume `tproxy-2048_state` and Caddy certificate volume
`tproxy-2048_caddy_data` (check names with `docker volume ls` or `podman volume ls`).

`site/` is a source snapshot of the MIT-licensed original 2048; keep `LICENSE.txt`.

## Security notes

- This is an independently assembled example of an experimental, proof-of-concept relay.
- Access logging of raw URLs and headers is disabled: bridge/session credentials can
  appear in HTTP paths or WebSocket metadata.
- Persistent `token.key` is not reconstructed from the client secret, regenerated at
  each startup, or put inside the public site.
- Backend MTProxy is not directly published; its bind inside Docker's shared network
  namespace is *not* a universal firewall guarantee. Preserve host/provider firewall.
- Full container startup has not been tested here. Verify readiness
  and Telegram connectivity on the target VPS before relying on it.

Upstreams:
- https://github.com/telegramdesktop/tproxy-server
- https://github.com/TelegramMessenger/MTProxy
- https://github.com/gabrielecirulli/2048
