#!/bin/bash
#
# local usage:
#   bash tests/postgres.sh
#
# requires docker and the compose stack running with --profile=postgres

set -euo pipefail

network_name=${1:-cheetah-infrastructure}
issuer=${2:-https://keycloak:8443/realms/local-development}
scope=${3:-postgres}
keycloak_token_url=${4:-http://localhost:1852/realms/local-development/protocol/openid-connect/token}

# Drives a Postgres SASL OAUTHBEARER auth with a pre-fetched bearer token,
# returning 0 iff the server replies AuthenticationOk. Inlined here because
# libpq-oauth only does interactive device-flow.
function oauth_login() {
	local host=$1 port=$2 db=$3 user=$4 token=$5
	local kind length auth_type
	local startup_len p_msg_len mech_nul_len cmsg_len client_msg

	# Helper: write a 32-bit big-endian integer to fd 3
		be4() {
			printf '\\x%02x\\x%02x\\x%02x\\x%02x' \
				$((($1 >> 24) & 0xff)) $((($1 >> 16) & 0xff)) \
				$((($1 >>  8) & 0xff)) $(( $1        & 0xff))
		}

	exec 3<>"/dev/tcp/${host}/${port}"

	# StartupMessage: [len:4][ver:4=196608][user\0<user>\0database\0<db>\0\0]
	startup_len=$(( 4 + 4 + 5 + ${#user} + 1 + 9 + ${#db} + 1 + 1 ))
	{
		be4 "$startup_len"
		printf '\x00\x03\x00\x00'
		printf 'user\x00%s\x00database\x00%s\x00\x00' "$user" "$db"
	} >&3

	# Expect AuthenticationSASL: 'R' + length + auth_type=10 + mechanism list
	kind=$(head -c 1 <&3)
	length=$((16#$(head -c 4 <&3 | od -An -tx1 | tr -d ' \n')))
	auth_type=$((16#$(head -c 4 <&3 | od -An -tx1 | tr -d ' \n')))
	[[ "$kind" == "R" && "$auth_type" == "10" ]] \
		|| { echo "expected SASL challenge, got kind=$kind auth_type=$auth_type"; return 1; }
	head -c $(( length - 8 )) <&3 >/dev/null

	# SASLInitialResponse: 'p' + len + "OAUTHBEARER\0" + cmsg_len + "n,,\x01auth=Bearer <token>\x01\x01"
	client_msg="n,,$(printf '\x01')auth=Bearer ${token}$(printf '\x01\x01')"
	mech_nul_len=12
	cmsg_len=${#client_msg}
	p_msg_len=$(( 4 + mech_nul_len + 4 + cmsg_len ))
	{
		printf 'p'
		be4 "$p_msg_len"
		printf 'OAUTHBEARER\x00'
		be4 "$cmsg_len"
		printf '%s' "$client_msg"
	} >&3

	# Expect AuthenticationOk: 'R' + length=8 + auth_type=0
	kind=$(head -c 1 <&3)
	length=$((16#$(head -c 4 <&3 | od -An -tx1 | tr -d ' \n')))
	auth_type=$((16#$(head -c 4 <&3 | od -An -tx1 | tr -d ' \n')))
	[[ "$kind" == "R" && "$auth_type" == "0" ]] \
		|| { echo "OAuth rejected: kind=$kind auth_type=$auth_type"; return 1; }
	exec 3<&-
}

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
if docker run --rm --network "${network_name}" -e PGPASSWORD=admin postgres:18.3-trixie \
	psql "host=postgres port=5432 dbname=app user=developer" -c "select 1" >/dev/null 2>&1; then
	echo "ERROR - Password based login unexpectedly succeeded"
	exit 1
fi

echo "INFO - Fetching service-account access token from Keycloak"
token=$(curl --fail -s -X POST "${keycloak_token_url}" \
	-d "grant_type=client_credentials" \
	-d "client_id=default-access" \
	-d "client_secret=default-access-secret" \
	-d "scope=${scope}" \
	| jq -r '.access_token')
[[ -n "${token}" && "${token}" != "null" ]] \
	|| { echo "ERROR - failed to obtain token from Keycloak"; exit 1; }

echo "INFO - Authenticating to postgres via SASL OAUTHBEARER"
if ! oauth_login localhost 5432 app default-access "${token}"; then
	echo "ERROR - OAuth authentication failed"
	exit 1
fi

echo "INFO - All checks passed"
