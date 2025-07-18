# build
ARG CADDY_VERSION=2.10.0

FROM --platform=$BUILDPLATFORM caddy:${CADDY_VERSION}-builder-alpine AS builder

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

## Fix godaddy build: `panic: internal error: can't find reason for requirement on google.golang.org/appengine@v1.6.6`
## Usage: `xcaddy build --with github.com/caddy-dns/godaddy=/root/caddy-dns-godaddy`
# RUN git clone --depth=1 https://github.com/caddy-dns/godaddy /root/caddy-dns-godaddy && \
# 	cd /root/caddy-dns-godaddy && \
# 	rm go.mod go.sum && \
# 	go mod init github.com/caddy-dns/godaddy && \
# 	go mod tidy

# forwardproxy
RUN git clone --depth=1 https://github.com/zedifen/forwardproxy --branch naive /root/forwardproxy && \
	cd /root/forwardproxy && \
	govesion="$(go env GOVERSION)" && \
	sed -i "s/^toolchain.*/toolchain ${govesion}/" go.mod && \
	go mod tidy
	# go get -u all && \
	# go mod tidy

RUN GOOS=linux GOARCH=$TARGETARCH xcaddy build $CADDY_VERSION \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddy-dns/azure \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/duckdns \
    --with github.com/caddy-dns/porkbun \
    --with github.com/caddy-dns/tencentcloud \
    --with github.com/libdns/digitalocean \
    --with github.com/libdns/namesilo \
    --with github.com/caddyserver/certmagic \
    --with github.com/caddyserver/forwardproxy@caddy2=/root/forwardproxy \
    --with github.com/abiosoft/caddy-exec \
    --with github.com/imgk/caddy-trojan \
    --with github.com/kirsch33/realip \
    --with github.com/lindenlab/caddy-s3-proxy \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/mholt/caddy-dynamicdns \
    --with github.com/mholt/caddy-events-exec \
    --with github.com/mholt/caddy-grpc-web \
    --with github.com/mholt/caddy-l4 \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/mholt/caddy-webdav \
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/WingLim/caddy-webhook \
    --with github.com/xcaddyplugins/caddy-trusted-cloudfront
    # --with github.com/caddy-dns/digitalocean \
    # --with github.com/caddy-dns/godaddy=/root/caddy-dns-godaddy \
    # --with github.com/caddy-dns/googleclouddns \
    # --with github.com/caddy-dns/namesilo \
    # --with github.com/caddyserver/forwardproxy@caddy2=github.com/zedifen/forwardproxy@naive \
    # --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \

# deploy
FROM caddy:${CADDY_VERSION}-alpine AS deploy

LABEL Maintainer="Ansley Leung" \
    Description="Self-host Caddy server" \
    License="MIT License" \
    CaddyServer="2.10.0"

RUN apk update && \
    apk upgrade && \
    apk add --no-cache coreutils ca-certificates curl git nss-tools tzdata && \
    rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

WORKDIR /var/www/html

COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT [ "caddy", "run", "--config=/etc/caddy/Caddyfile"]
