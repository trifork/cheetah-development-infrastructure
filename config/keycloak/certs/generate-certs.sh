#!/usr/bin/env sh
# Generates the self-signed Keycloak HTTPS cert. Designed to run inside the
# `keycloak-cert-init` compose service (Alpine + openssl), but also works on a
# developer host that has openssl, by falling back to the script's own dir.
#
# SANs cover `keycloak` (in-cluster), `localhost` and `127.0.0.1` (host browser
# hitting https://localhost:8443/admin/).
set -eu

cert_dir="${CERT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
crt="${cert_dir}/keycloak.pem"
key="${cert_dir}/keycloak-key.pem"

if [ -f "$crt" ] && [ -f "$key" ]; then
  echo "Certs already exist at $cert_dir - skipping."
  exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
  apk add --no-cache openssl >/dev/null
fi

mkdir -p "$cert_dir"

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$key" \
  -out "$crt" \
  -days 3650 \
  -subj "/CN=keycloak" \
  -addext "subjectAltName=DNS:keycloak,DNS:localhost,IP:127.0.0.1"

# 0644 so non-root container users (keycloak uid 1000) can read the key
# regardless of which host uid created it (e.g. CI runner uid 1001).
chmod 0644 "$crt" "$key"

echo "Generated:"
echo "  $crt"
echo "  $key"
