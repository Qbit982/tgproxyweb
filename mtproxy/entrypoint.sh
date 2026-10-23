#!/bin/sh
set -eu

backend_secret="$(cat /state/mtproxy.secret)"
workers="${MTPROXY_WORKERS:-1}"
max_connections="${MTPROXY_MAX_CONNECTIONS:-4096}"

if ! printf '%s\n' "$backend_secret" | grep -Eq '^[0-9a-f]{32}$'; then
    echo 'invalid backend secret' >&2
    exit 2
fi

if ! printf '%s\n' "$workers" | grep -Eq '^[1-9][0-9]*$'; then
    echo 'MTPROXY_WORKERS must be a positive integer' >&2
    exit 2
fi

if ! printf '%s\n' "$max_connections" | grep -Eq '^[1-9][0-9]*$'; then
    echo 'MTPROXY_MAX_CONNECTIONS must be a positive integer' >&2
    exit 2
fi

test -r /routes/proxy-secret
test -r /routes/proxy-multi.conf

exec /usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8888 \
    -H 2398 \
    -S "$backend_secret" \
    --aes-pwd /routes/proxy-secret /routes/proxy-multi.conf \
    -M "$workers" \
    -C "$max_connections"
