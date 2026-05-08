#!/bin/bash
set -e

# Install libcurl4 if not already present (runtime dep of pg_oidc_validator.so).
# Skipped on subsequent starts once cached in the image layer.
if ! [ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 ]; then
    echo "Installing libcurl4 for pg_oidc_validator..."
    apt-get update -qq && apt-get install -y --no-install-recommends libcurl4
    rm -rf /var/lib/apt/lists/*
fi

exec docker-entrypoint.sh "$@"
