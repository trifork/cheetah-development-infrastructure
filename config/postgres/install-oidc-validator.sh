#!/usr/bin/env bash
# Builds pg_oidc_validator.so from source at $VALIDATOR_REPO_URL @ $VALIDATOR_VERSION
# and writes it to the shared volume mounted by postgres.
# Rebuild: `docker compose --profile postgres down -v && up`.
set -euo pipefail

: "${VALIDATOR_REPO_URL:?VALIDATOR_REPO_URL must be set}"
: "${VALIDATOR_VERSION:?VALIDATOR_VERSION must be set (branch or tag)}"
out_file="${VALIDATOR_SO_PATH:-/validator-out/pg_oidc_validator.so}"
mkdir -p "$(dirname "$out_file")"

if [[ -f "$out_file" ]]; then
	echo "Validator already at $out_file - skipping."
	exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
	ca-certificates git make g++ pkg-config \
	libssl-dev libcurl4-openssl-dev libkrb5-dev \
	postgresql-server-dev-18

src=/tmp/pg_oidc_validator
rm -rf "$src"
git clone --depth 1 --recurse-submodules --branch "$VALIDATOR_VERSION" \
	"$VALIDATOR_REPO_URL" "$src"
make -C "$src" USE_PGXS=1 -j"$(nproc)"
cp "$src/pg_oidc_validator.so" "$out_file"
chmod 0644 "$out_file"

rm -rf "$src"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Installed validator $VALIDATOR_VERSION -> $out_file"
