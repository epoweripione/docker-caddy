# build
FROM --platform=$BUILDPLATFORM caddy:2-builder-alpine AS builder

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

ENV CADDY_VERSION v2.6.4

# Fix godaddy build: `panic: internal error: can't find reason for requirement on google.golang.org/appengine@v1.6.6`
# Usage: `xcaddy build --with github.com/caddy-dns/godaddy=/root/caddy-dns-godaddy`
RUN git clone --depth=1 https://github.com/caddy-dns/godaddy /root/caddy-dns-godaddy && \
	cd /root/caddy-dns-godaddy && \
	rm go.mod go.sum && \
	go mod init github.com/caddy-dns/godaddy && \
	go mod tidy

RUN GOOS=linux GOARCH=$TARGETARCH xcaddy build \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddy-dns/azure \
    --with github.com/caddy-dns/cloudflare@a9d3ae2690a1d232bc9f8fc8b15bd4e0a6960eec \
    --with github.com/caddy-dns/digitalocean \
    --with github.com/caddy-dns/dnspod \
    --with github.com/caddy-dns/godaddy=/root/caddy-dns-godaddy \
    --with github.com/caddy-dns/googleclouddns \
    --with github.com/caddy-dns/namesilo \
    --with github.com/mholt/caddy-dynamicdns \
    --with github.com/caddyserver/forwardproxy@caddy2=github.com/zedifen/forwardproxy@4e4d3b371b940f6f886fe0e051feb352d1d340ce \
    --with github.com/mholt/caddy-webdav \
    --with github.com/mholt/caddy-l4@38bd80163b43568cab5a12e09b41923bcac99f86 \
    --with github.com/lindenlab/caddy-s3-proxy \
    --with github.com/mholt/caddy-grpc-web \
    --with github.com/kirsch33/realip \
    --with github.com/mholt/caddy-ratelimit
    # --with github.com/caddyserver/forwardproxy@caddy2=github.com/sagernet/forwardproxy@naive \
    # --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
    # --with github.com/mholt/caddy-events-exec \
    # --with github.com/abiosoft/caddy-exec \
    # --with github.com/WingLim/caddy-webhook

# deploy
FROM caddy:2-alpine AS deploy

LABEL Maintainer="Ansley Leung" \
    Description="Self-host Caddy server" \
    License="MIT License" \
    CaddyServer="2.6.4"

RUN apk update && \
    apk upgrade && \
    apk add --no-cache coreutils ca-certificates curl git nss-tools && \
    rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

WORKDIR /var/www/html

COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT [ "caddy", "run", "--config=/etc/caddy/Caddyfile"]
