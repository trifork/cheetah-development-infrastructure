#!/usr/bin/env bash
# Provisions upstream Percona pg_oidc_validator.so into the shared volume
# mounted by postgres. Prebuilt .deb first; source build as fallback.
# Re-run by dropping the postgres-validator-lib volume.
set -euo pipefail

out_file="${VALIDATOR_SO_PATH:-/validator-out/pg_oidc_validator.so}"
mkdir -p "$(dirname "$out_file")"

if [[ -f "$out_file" ]]; then
  echo "Validator already at $out_file - skipping."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl

if curl -fsSL -o /tmp/pg-oidc-validator-pgdg18.deb \
    https://github.com/percona/pg_oidc_validator/releases/download/latest/pg-oidc-validator-pgdg18.deb \
  && apt-get install -y --no-install-recommends /tmp/pg-oidc-validator-pgdg18.deb; then
  cp /usr/lib/postgresql/18/lib/pg_oidc_validator.so "$out_file"
else
  echo "Prebuilt .deb unavailable, building from source..."
  rm -f /tmp/pg-oidc-validator-pgdg18.deb
  apt-get install -y --no-install-recommends \
    git make g++ pkg-config \
    libssl-dev libcurl4-openssl-dev libkrb5-dev \
    postgresql-server-dev-18
  rm -rf /tmp/pg_oidc_validator
  git clone --depth 1 --recurse-submodules \
    https://github.com/percona/pg_oidc_validator.git /tmp/pg_oidc_validator
  make -C /tmp/pg_oidc_validator USE_PGXS=1 -j"$(nproc)"
  cp /tmp/pg_oidc_validator/pg_oidc_validator.so "$out_file"
  rm -rf /tmp/pg_oidc_validator
fi

chmod 0644 "$out_file"
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/pg-oidc-validator-pgdg18.deb 2>/dev/null || true

echo "Installed validator -> $out_file"
