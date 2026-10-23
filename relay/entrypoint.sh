#!/bin/sh
set -eu

umask 077

case "${DOMAIN:-}" in
    *.*) ;;
    *)
        echo 'Set DOMAIN to an ASCII DNS hostname' >&2
        exit 2
        ;;
esac

if ! printf '%s\n' "$DOMAIN" | grep -Eq '^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$'; then
    echo 'Set DOMAIN to an ASCII DNS hostname' >&2
    exit 2
fi

relay_secret="$(cat /state/relay.secret)"

if ! printf '%s\n' "$relay_secret" | grep -Eq '^[0-9a-f]{32}$'; then
    echo 'invalid relay secret' >&2
    exit 2
fi

cat > /tmp/profiles.json <<EOF
{
  "profiles": [
    {
      "name": "default",
      "secret": "$relay_secret",
      "backend": "127.0.0.1:2398",
      "carrier_mode": "https"
    }
  ]
}
EOF

cat > /tmp/config.json <<EOF
{
  "public_hostname": "$DOMAIN",
  "base_path": "",
  "listen": "127.0.0.1:8080",
  "admin_listen": "127.0.0.1:8081",
  "public_dir": "/srv/tproxy-site",
  "static_routes": "exact",
  "profiles_file": "/tmp/profiles.json",
  "token_key_file": "/state/token.key",
  "enable_pprof": false
}
EOF

chmod 0400 /tmp/config.json /tmp/profiles.json

/usr/local/bin/tproxy-server \
    -config /tmp/config.json \
    -profiles-file /tmp/profiles.json \
    -check

exec /usr/local/bin/tproxy-server \
    -config /tmp/config.json \
    -profiles-file /tmp/profiles.json
