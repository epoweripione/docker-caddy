# build
FROM --platform=$BUILDPLATFORM caddy:2-builder-alpine AS builder

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

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
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/digitalocean \
    --with github.com/caddy-dns/dnspod \
    --with github.com/caddy-dns/godaddy=/root/caddy-dns-godaddy \
    --with github.com/caddy-dns/googleclouddns \
    --with github.com/caddy-dns/namesilo \
    --with github.com/mholt/caddy-dynamicdns \
    --with github.com/mastercactapus/caddy2-proxyprotocol \
    --with github.com/caddyserver/forwardproxy@caddy2=github.com/sagernet/forwardproxy@naive \
    --with github.com/mholt/caddy-webdav \
    --with github.com/mholt/caddy-l4 \
    --with github.com/lindenlab/caddy-s3-proxy \
    --with github.com/mholt/caddy-grpc-web \
    --with github.com/kirsch33/realip
    # --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive \
    # --with github.com/mholt/caddy-events-exec \
    # --with github.com/abiosoft/caddy-exec \
    # --with github.com/WingLim/caddy-webhook

# deploy
FROM caddy:2-alpine AS deploy

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

WORKDIR /var/www/html

COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT [ "caddy", "run", "--config=/etc/caddy/Caddyfile"]
