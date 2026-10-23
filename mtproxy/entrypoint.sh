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

internal_ip="$(hostname -I | awk '{print $1}')"
public_ip="${MTPROXY_PUBLIC_IP:-}"

if [ -z "$public_ip" ]; then
    public_ip="$(getent ahostsv4 "${DOMAIN:-}" | awk 'NR == 1 {print $1}')"
fi

if ! printf '%s\n' "$internal_ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo 'Could not determine the container IPv4 address' >&2
    exit 2
fi

if ! printf '%s\n' "$public_ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo 'Set MTPROXY_PUBLIC_IP to the public IPv4 address of the VPS' >&2
    exit 2
fi

exec /usr/local/bin/mtproto-proxy \
    -u mtproxy \
    -p 8888 \
    -H 2398 \
    -S "$backend_secret" \
    --aes-pwd /routes/proxy-secret /routes/proxy-multi.conf \
    --nat-info "$internal_ip:$public_ip" \
    -M "$workers" \
    -C "$max_connections"
