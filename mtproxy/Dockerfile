FROM docker.io/library/debian:bookworm-slim AS builder

ARG MTPROXY_COMMIT
ARG MTPROXY_SHA256

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl --fail --silent --show-error --location \
        --proto '=https' --proto-redir '=https' --tlsv1.2 \
        -o mtproxy.tar.gz \
        "https://github.com/TelegramMessenger/MTProxy/archive/${MTPROXY_COMMIT}.tar.gz" \
    && printf '%s  mtproxy.tar.gz\n' "$MTPROXY_SHA256" | sha256sum -c - \
    && mkdir src \
    && tar -C src --strip-components=1 -xzf mtproxy.tar.gz \
    && make -C src -j"$(nproc)" \
    && test -x src/objs/bin/mtproto-proxy

FROM docker.io/library/debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libssl3 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && useradd \
        --system \
        --uid 10002 \
        --home /nonexistent \
        --shell /usr/sbin/nologin \
        mtproxy

COPY --from=builder /build/src/objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy
COPY entrypoint.sh /usr/local/bin/entrypoint

RUN chmod 0755 /usr/local/bin/entrypoint /usr/local/bin/mtproto-proxy

USER 10002:10002

ENTRYPOINT ["/usr/local/bin/entrypoint"]
