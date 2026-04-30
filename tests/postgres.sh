#!/bin/bash

# local usage:
#   bash tests/postgres.sh
#
# requires docker and the compose stack running with --profile=postgres

set -euo pipefail

network_name=${1:-cheetah-infrastructure}
issuer=${2:-http://keycloak:1852/realms/local-development}
scope=${3:-postgres}

echo "INFO - Verifying pg_hba oauth entries in postgres container"
if ! docker exec postgres grep -q "oauth issuer=${issuer} scope=\"${scope}\"" /etc/postgresql/pg_hba.conf; then
  echo "ERROR - OAuth pg_hba entry not found"
  exit 1
fi

echo "INFO - Verifying no host password/basic auth entries are configured"
if docker exec postgres grep -E "^host\s+.*\s+(password|md5|scram-sha-256)" /etc/postgresql/pg_hba.conf; then
  echo "ERROR - Found password/basic auth entry in pg_hba.conf"
  exit 1
fi

echo "INFO - Verifying password login fails for host connection"
if docker run --rm --network "${network_name}" -e PGPASSWORD=admin postgres:18.3-bookworm \
  psql "host=postgres port=5432 dbname=app user=developer" -c "select 1" >/dev/null 2>&1; then
  echo "ERROR - Password based login unexpectedly succeeded"
  exit 1
fi

echo "INFO - OAuth-only auth checks passed"
echo "INFO - Manual OAuth login test:"
echo "psql 'host=localhost port=5432 dbname=app user=developer oauth_issuer=http://localhost:1852/realms/local-development oauth_client_id=postgres'"
