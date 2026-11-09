FROM pasarguard/node:latest

RUN apk add --no-cache openssl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV NODE_HOST=0.0.0.0 \
    SERVICE_PORT=8080 \
    SSL_CERT_FILE=/var/lib/pg-node/certs/ssl_cert.pem \
    SSL_KEY_FILE=/var/lib/pg-node/certs/ssl_key.pem

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
