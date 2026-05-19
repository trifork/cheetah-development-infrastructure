#!/bin/bash
set -e

if ! [ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 ]; then
    echo "Installing libcurl4 for pg_oidc_validator..."
    apt-get update -qq
    apt-get install -y --no-install-recommends libcurl4 ca-certificates
    rm -rf /var/lib/apt/lists/*
fi

# Trust the self-signed Keycloak cert so the validator can reach keycloak:8443.
if [ ! -f /usr/local/share/ca-certificates/keycloak-ca.crt ] \
   && [ -f /etc/keycloak-ca/keycloak.pem ]; then
    cp /etc/keycloak-ca/keycloak.pem /usr/local/share/ca-certificates/keycloak-ca.crt
    update-ca-certificates
fi

exec docker-entrypoint.sh "$@"
