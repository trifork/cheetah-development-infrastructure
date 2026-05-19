#!/bin/sh
# Generates the local-dev Keycloak self-signed cert into /certs (a docker
# named volume shared with keycloak + postgres). Idempotent.
set -eu

cd /certs
[ -f keycloak.pem ] && exit 0

command -v openssl >/dev/null || apk add --no-cache openssl >/dev/null

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout keycloak-key.pem -out keycloak.pem \
  -days 3650 -subj /CN=keycloak \
  -addext subjectAltName=DNS:keycloak,DNS:localhost,IP:127.0.0.1

chmod 0644 keycloak.pem keycloak-key.pem
