#!/usr/bin/env bash
# Generates a self-signed cert for the local-dev Keycloak HTTPS listener.
# SANs cover both `keycloak` (used inside the docker network) and `localhost`/127.0.0.1
# (so a host browser can hit https://localhost:8443 if `keycloak` isn't in /etc/hosts).
#
# Run: bash config/keycloak/certs/generate-certs.sh
set -euo pipefail

cert_dir="$(cd "$(dirname "$0")" && pwd)"
crt="${cert_dir}/keycloak.pem"
key="${cert_dir}/keycloak-key.pem"

if [[ -f "$crt" && -f "$key" ]]; then
  echo "Cert already exists at $crt - delete it first to regenerate."
  exit 0
fi

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$key" \
  -out "$crt" \
  -days 3650 \
  -subj "/CN=keycloak" \
  -addext "subjectAltName=DNS:keycloak,DNS:localhost,IP:127.0.0.1"

chmod 0644 "$crt"
chmod 0600 "$key"

echo "Generated:"
echo "  $crt"
echo "  $key"
