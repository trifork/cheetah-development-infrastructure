#!/bin/bash

set -euo pipefail

#
# Test authentication using basic auth and JWT
#

function get_default_access_token() {
	local tenant=$1
	local response
	local access_token
	response=$(
		curl --fail -s -X 'POST' \
			'http://keycloak:1852/realms/local-development/protocol/openid-connect/token' \
			-H 'accept: */*' \
			-H 'Content-Type: application/x-www-form-urlencoded' \
			-H 'cache-control: no-cache' \
			-d "grant_type=client_credentials&scope=&client_id=$tenant&client_secret="
	)
	access_token=$(printf '%s' "$response" | jq -r '.access_token')
	echo "$access_token"
}

# function get_customaccess_token() {
# 	local tenant=$1
# 	local roles=$2 # backend roles
# 	local response
# 	local access_token
# 	response=$(curl -s -X 'POST' \
# 		'http://cheetahoauthsimulator:80/oauth2/customtoken' \
# 		-H 'accept: */*' \
# 		-H 'Content-Type: application/json' \
# 		-H 'cache-control: no-cache' \
# 		-d "{
#     \"clientId\": \"$tenant\",
#     \"claims\": {
#       \"roles\": \"$roles\",
#       \"osuser\": \"hest\"
#     },
#     \"expiresInMinutes\": 120
#   }")
# 	access_token=$(printf '%s' "$response" | jq -r '.access_token')
# 	echo "$access_token"
# }

TENANT=flink
cache_header="cache-control: no-cache"
os_url="http://opensearch:9200"

service_token=$(get_default_access_token $TENANT)
#admin_token=$(get_customaccess_token $TENANT 'admin')

echo "INFO - indices lookup with anonymous user:"
if curl -s --fail-with-body -k "$os_url/_cat/indices" -H "$cache_header"; then
	echo
	echo "ERROR - Anonymous authentication enabled"
	exit 1
fi

echo
echo "Test jwt auth:"
if ! curl --fail-with-body -s -X GET "$os_url/_cat/indices" -H "Authorization: bearer $(printf '%s' "$service_token")"; then
	echo
	echo "ERROR - Authorized access using jwt failed"
	exit 1
fi

echo
echo "Test basic auth:"
if ! curl --fail-with-body -s -u 'admin:admin' -X GET "$os_url/_cat/indices"; then
	echo
	echo "ERROR - Authorized access using admin credentials failed"
	exit 1
fi
