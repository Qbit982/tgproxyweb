#!/bin/sh
set -eu

umask 077
mkdir -p /state

if [ ! -e /state/token.key ]; then
    head -c 32 /dev/urandom > /state/token.key
fi

if [ "$(wc -c < /state/token.key)" -ne 32 ]; then
    echo 'token.key must be 32 bytes' >&2
    exit 1
fi

chown 10001:10001 /state/token.key
chmod 0400 /state/token.key

if [ ! -e /state/relay.secret ]; then
    od -An -tx1 -N16 /dev/urandom | tr -d ' \n' > /state/relay.secret
fi
relay_secret="$(cat /state/relay.secret)"

if ! printf '%s\n' "$relay_secret" | grep -Eq '^[0-9a-f]{32}$'; then
    echo 'invalid relay secret' >&2
    exit 1
fi

chown 10001:10001 /state/relay.secret
chmod 0400 /state/relay.secret

if [ ! -e /state/mtproxy.secret ]; then
    printf '%s' "$relay_secret" > /state/mtproxy.secret
fi

if [ "$(cat /state/mtproxy.secret)" != "$relay_secret" ]; then
    echo 'secret mismatch' >&2
    exit 1
fi

chown 10002:10002 /state/mtproxy.secret
chmod 0400 /state/mtproxy.secret
chmod 0755 /state
