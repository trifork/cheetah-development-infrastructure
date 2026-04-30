#!/usr/bin/env bash
set -euo pipefail

out_file="${VALIDATOR_SO_PATH:-/validator-out/pg_oidc_validator.so}"
out_dir="$(dirname "$out_file")"

mkdir -p "$out_dir"

if [[ -f "$out_file" ]]; then
  echo "Validator library already present at $out_file"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  make \
  g++ \
  pkg-config \
  libssl-dev

# Prefer the prebuilt package; fall back to source build if unavailable.
if curl -fsSL -o /tmp/pg-oidc-validator-pgdg18.deb \
  https://github.com/percona/pg_oidc_validator/releases/download/latest/pg-oidc-validator-pgdg18.deb; then
  if apt-get install -y --no-install-recommends /tmp/pg-oidc-validator-pgdg18.deb; then
    cp /usr/lib/postgresql/18/lib/pg_oidc_validator.so "$out_file"
  else
    rm -f /tmp/pg-oidc-validator-pgdg18.deb
  fi
fi

if [[ ! -f "$out_file" ]]; then
  rm -rf /tmp/pg_oidc_validator
  git clone --depth 1 --recurse-submodules https://github.com/percona/pg_oidc_validator.git /tmp/pg_oidc_validator
  make -C /tmp/pg_oidc_validator USE_PGXS=1 -j"$(nproc)"
  cp /tmp/pg_oidc_validator/pg_oidc_validator.so "$out_file"
fi

chmod 0644 "$out_file"

rm -rf /tmp/pg_oidc_validator
rm -f /tmp/pg-oidc-validator-pgdg18.deb
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Installed validator to $out_file"
