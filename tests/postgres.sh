#!/bin/bash

set -euo pipefail

#
# Test authentication to postgres via OAuth (SASL OAUTHBEARER)
#

PG_HOST=${1:-postgres}
PG_PORT=${2:-5432}
PG_DB=${3:-app}
OIDC_TOKEN_HOST=${4:-http://keycloak:1852}
TENANT=default-access

function get_default_access_token() {
	curl --fail -s -X POST \
		"${OIDC_TOKEN_HOST}/realms/local-development/protocol/openid-connect/token" \
		-H 'Content-Type: application/x-www-form-urlencoded' \
		-d "grant_type=client_credentials&scope=postgres&client_id=${TENANT}&client_secret=${TENANT}-secret" |
		jq -r '.access_token'
}

# Drives a PostgreSQL SASL OAUTHBEARER handshake over a raw TCP socket.
# Returns 0 iff the server replies AuthenticationOk.
function oauth_login() {
	local user=$1 token=$2
	local kind length auth_type hex startup_len client_msg cmsg_len

	be4() { printf '\\x%02x\\x%02x\\x%02x\\x%02x' $((($1 >> 24) & 0xff)) $((($1 >> 16) & 0xff)) $((($1 >> 8) & 0xff)) $(($1 & 0xff)); }

	exec 3<>"/dev/tcp/${PG_HOST}/${PG_PORT}"

	# StartupMessage: [len:4][ver:4][user\0<user>\0database\0<db>\0\0]
	startup_len=$((4 + 4 + 5 + ${#user} + 1 + 9 + ${#PG_DB} + 1 + 1))
	printf '%b\x00\x03\x00\x00user\x00%s\x00database\x00%s\x00\x00' \
		"$(be4 "$startup_len")" "$user" "$PG_DB" >&3

	# Expect AuthenticationSASL: 'R' + len + auth_type=10 + mechanisms.
	# Use `dd` rather than `head` because busybox head buffers socket reads.
	kind=$(dd bs=1 count=1 <&3 2>/dev/null)
	hex=$(dd bs=1 count=4 <&3 2>/dev/null | od -An -tx1 | tr -d ' \n'); length=$((16#${hex:-0}))
	hex=$(dd bs=1 count=4 <&3 2>/dev/null | od -An -tx1 | tr -d ' \n'); auth_type=$((16#${hex:-0}))
	[[ "$kind" == "R" && "$auth_type" == "10" ]] || return 1
	dd bs=1 count=$((length - 8)) <&3 >/dev/null 2>&1

	# SASLInitialResponse: 'p' + len + "OAUTHBEARER\0" + cmsg_len + GS2-Bearer
	client_msg="n,,$(printf '\x01')auth=Bearer ${token}$(printf '\x01\x01')"
	cmsg_len=${#client_msg}
	printf 'p%bOAUTHBEARER\x00%b%s' \
		"$(be4 $((4 + 12 + 4 + cmsg_len)))" "$(be4 "$cmsg_len")" "$client_msg" >&3

	# Expect AuthenticationOk: 'R' + len=8 + auth_type=0
	kind=$(dd bs=1 count=1 <&3 2>/dev/null)
	hex=$(dd bs=1 count=4 <&3 2>/dev/null | od -An -tx1 | tr -d ' \n'); length=$((16#${hex:-0}))
	hex=$(dd bs=1 count=4 <&3 2>/dev/null | od -An -tx1 | tr -d ' \n'); auth_type=$((16#${hex:-0}))
	exec 3<&-
	[[ "$kind" == "R" && "$auth_type" == "0" ]]
}

echo "INFO - Fetching $TENANT access token"
token=$(get_default_access_token)
[[ -n "${token}" && "${token}" != "null" ]] || { echo "ERROR - failed to obtain token"; exit 1; }

echo "INFO - Authenticating to postgres as $TENANT via SASL OAUTHBEARER"
if ! oauth_login "$TENANT" "$token"; then
	echo "ERROR - OAuth authentication failed"
	exit 1
fi

echo "Finished test sucessfully."
