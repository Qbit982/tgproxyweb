#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
. ./.env

proxy_secret="$(./scripts/compose.sh exec -T relay cat /state/relay.secret)"

if ! printf '%s\n' "$proxy_secret" | grep -Eq '^[0-9a-f]{32}$'; then
    echo 'invalid proxy secret' >&2
    exit 1
fi

title_style=''
reset_style=''

if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR+x}" ]; then
    title_style="$(printf '\033[1;36m')"
    reset_style="$(printf '\033[0m')"
fi

printf '\n%sTelegram WEB Proxy%s\n\n' "$title_style" "$reset_style"
printf '  Server: %s\n' "$DOMAIN"
printf '  Secret: %s\n' "$proxy_secret"
printf '\n%sConnect in Telegram:%s\n\n' "$title_style" "$reset_style"
printf 'tg://webproxy?server=%s&secret=%s\n\n' "$DOMAIN" "$proxy_secret"
