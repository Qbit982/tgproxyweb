FROM docker.io/library/golang:1.26.5-alpine AS builder

ARG TPROXY_COMMIT

RUN test -n "$TPROXY_COMMIT" \
    && printf '%s\n' "$TPROXY_COMMIT" | grep -Eq '^[0-9a-f]{40}$'

RUN apk add --no-cache \
    ca-certificates \
    git

WORKDIR /src

RUN git init \
    && git remote add origin https://github.com/telegramdesktop/tproxy-server.git \
    && git fetch --depth=1 origin "$TPROXY_COMMIT" \
    && git checkout --detach FETCH_HEAD

RUN go test ./...

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /out/tproxy-server \
    ./cmd/tproxy-server

FROM docker.io/library/alpine:3.22

RUN apk add --no-cache \
        ca-certificates \
        wget \
    && addgroup -g 10001 -S tproxy \
    && adduser -u 10001 -S -D -H -G tproxy tproxy

COPY --from=builder /out/tproxy-server /usr/local/bin/tproxy-server
COPY entrypoint.sh /usr/local/bin/entrypoint

RUN chmod 0755 /usr/local/bin/tproxy-server /usr/local/bin/entrypoint

USER 10001:10001

ENTRYPOINT ["/usr/local/bin/entrypoint"]
