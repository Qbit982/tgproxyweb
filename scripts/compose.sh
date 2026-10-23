#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

container_engine="${CONTAINER_ENGINE:-auto}"

case "$container_engine" in
    auto)
        for container_engine in docker podman; do
            if command -v "$container_engine" >/dev/null 2>&1 &&
                "$container_engine" compose version >/dev/null 2>&1; then
                exec "$container_engine" compose "$@"
            fi
        done

        echo 'Docker Compose v2 or Podman with a Compose provider is required' >&2
        exit 1
        ;;
    docker|podman)
        exec "$container_engine" compose "$@"
        ;;
    *)
        echo 'CONTAINER_ENGINE must be auto, docker or podman' >&2
        exit 2
        ;;
esac
