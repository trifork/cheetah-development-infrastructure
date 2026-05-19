#!/bin/bash
set -e

# Install libcurl4 if not already present (runtime dep of pg_oidc_validator.so).
# Skipped on subsequent starts once cached in the image layer.
if ! [ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 ]; then
    echo "Installing libcurl4 for pg_oidc_validator..."
    apt-get update -qq
    apt-get install -y --no-install-recommends libcurl4 ca-certificates
    rm -rf /var/lib/apt/lists/*
fi

# Trust the self-signed Keycloak cert so the validator can fetch OIDC
# discovery + JWKS from https://keycloak:8443 over the docker network.
# Idempotent: short-circuits once the cert is in the system trust store.
if [ ! -f /usr/local/share/ca-certificates/keycloak-ca.crt ] \
   && [ -f /etc/keycloak-ca/keycloak.pem ]; then
    echo "Installing Keycloak dev cert as trusted CA..."
    cp /etc/keycloak-ca/keycloak.pem /usr/local/share/ca-certificates/keycloak-ca.crt
    update-ca-certificates
fi

exec docker-entrypoint.sh "$@"
