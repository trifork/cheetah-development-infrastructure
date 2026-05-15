#!/usr/bin/env bash
# Builds pg_oidc_validator.so from $VALIDATOR_SRC_DIR and writes it to
# $VALIDATOR_SO_PATH. Used by the `validator-build` compose profile to
# regenerate the committed binary at config/postgres/validator/.
#
# Set VALIDATOR_FORCE_REBUILD=1 to overwrite an existing .so (default off so
# accidentally bind-mounting an existing output dir is a no-op).
set -euo pipefail

out_file="${VALIDATOR_SO_PATH:-/validator-out/pg_oidc_validator.so}"
src_dir="${VALIDATOR_SRC_DIR:-/pg_oidc_validator-src}"
force="${VALIDATOR_FORCE_REBUILD:-0}"
out_dir="$(dirname "$out_file")"

mkdir -p "$out_dir"

if [[ -f "$out_file" && "$force" != "1" ]]; then
  echo "Validator already at $out_file - skipping rebuild (set VALIDATOR_FORCE_REBUILD=1 to overwrite)."
  exit 0
fi

if [[ ! -d "$src_dir" ]]; then
  echo "ERROR: validator source not bind-mounted at $src_dir (see postgres.yaml)" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    git make g++ pkg-config \
    libssl-dev libcurl4-openssl-dev libkrb5-dev \
    postgresql-server-dev-18

# Build out-of-tree so artifacts don't leak back into the bind mount.
build_dir=/tmp/pg_oidc_validator-build
rm -rf "$build_dir"
cp -r "$src_dir" "$build_dir"

make -C "$build_dir" USE_PGXS=1 -j"$(nproc)"
cp "$build_dir/pg_oidc_validator.so" "$out_file"
chmod 0644 "$out_file"

apt-get clean
rm -rf /var/lib/apt/lists/* "$build_dir"

echo "Built validator from $src_dir -> $out_file"
