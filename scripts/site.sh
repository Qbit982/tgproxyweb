#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if ! command -v git >/dev/null 2>&1; then
    echo 'git is required' >&2
    exit 1
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM
source_dir="$temporary_dir/2048"

git clone --depth 1 https://github.com/gabrielecirulli/2048.git "$source_dir"

mkdir -p site
cp "$source_dir/index.html" \
    "$source_dir/favicon.ico" \
    "$source_dir/LICENSE.txt" \
    site/
cp -R "$source_dir/js" "$source_dir/style" "$source_dir/meta" site/

cat > site/404.html <<'EOF'
<!doctype html><html lang="en"><meta charset="utf-8"><title>Not found</title><h1>404 — Not found</h1><p><a href="/">Return to the game</a></p></html>
EOF

git -C "$source_dir" rev-parse HEAD > site-revision.txt
printf 'Installed original 2048 into ./site (revision in site-revision.txt)\n'
