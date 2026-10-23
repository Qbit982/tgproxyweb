#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
umask 077

if ! command -v git >/dev/null 2>&1; then
    echo 'git is required' >&2
    exit 1
fi

./scripts/compose.sh version >/dev/null

if [ ! -f .env ]; then
    cp .env.example .env
fi

if ! grep -Eq '^TPROXY_COMMIT=[0-9a-f]{40}$' .env; then
    upstream_commit="$(
        git ls-remote https://github.com/telegramdesktop/tproxy-server.git HEAD |
            awk '{print $1}'
    )"

    if ! printf '%s\n' "$upstream_commit" | grep -Eq '^[0-9a-f]{40}$'; then
        echo 'Failed to pin upstream commit' >&2
        exit 1
    fi

    sed '/^TPROXY_COMMIT=/d' .env > .env.tmp
    printf 'TPROXY_COMMIT=%s\n' "$upstream_commit" >> .env.tmp
    mv .env.tmp .env

    echo "Pinned upstream commit: $upstream_commit"
    echo "Review: https://github.com/telegramdesktop/tproxy-server/commit/$upstream_commit"
fi

chmod 0600 .env

if [ ! -f site/index.html ]; then
    ./scripts/site.sh
fi

cat <<'EOF'

Edit DOMAIN and ACME_EMAIL in .env, then run:
  ./scripts/compose.sh config -q
  ./scripts/compose.sh up -d --build
EOF
