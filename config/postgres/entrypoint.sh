#!/bin/bash
set -e

if ! [ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 ]; then
    echo "Installing libcurl4 for pg_oidc_validator..."
    apt-get update -qq
    apt-get install -y --no-install-recommends libcurl4
    rm -rf /var/lib/apt/lists/*
fi

exec docker-entrypoint.sh "$@"
