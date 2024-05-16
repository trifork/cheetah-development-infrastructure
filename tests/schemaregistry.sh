#!/bin/bash

# local: bash tests/schemaregistry.sh http://localhost:8081 http://localhost:1852

set -euo pipefail

SCHEMAREGISTRY_HOST=${1:-http://schema-registry:8080} # schema registry url
OIDC_TOKEN_HOST=${2:-http://keycloak:1852}
TENANT=default-access
GROUPID=1245
empty_token=""

echo "Testing $SCHEMAREGISTRY_HOST"

function get_default_access_token() {
	local tenant=$1
	local response

	response=$(
		http --check-status --ignore-stdin --follow --all --form POST "${OIDC_TOKEN_HOST}/realms/local-development/protocol/openid-connect/token" \
			accept:'*/*' \
			Content-Type:'application/x-www-form-urlencoded' \
			cache-control:'no-cache' \
			grant_type=client_credentials scope=schema-registry client_id="${tenant}" client_secret="${tenant}-secret"
	)
	local access_token
	access_token=$(printf '%s' "$response" | jq -r '.access_token')
	echo "$access_token"
}

function test_anonymous_user() {
	if ! http --check-status --ignore-stdin "$SCHEMAREGISTRY_HOST/apis/registry/v2/users/me" cache-control:'no-cache'; then
		echo "ERROR - Anonymous readonly not allowed"
		return 1
	fi
	return 0
}

function test_jwt_auth() {
	local token=$1
	local response
	if http --check-status --ignore-stdin "$SCHEMAREGISTRY_HOST/apis/registry/v2/users/me" Authorization:"bearer $token"; then
		echo "INFO - Authorized access using jwt successful"
	else
		echo "ERROR - Authorized access using jwt failed. Err: " $?
		return 1
	fi
}

function upload_api_description() {
	local group_id=$1
	local token=$2
	local api_description
	api_description='{
		"type": "OpenAPI",
		"info": {
			"title": "My API",
			"version": "1.0.0"
		},
		"paths": {
			"/users": {
				"get": {
					"summary": "Get all users",
					"responses": {
						"200": {
							"description": "Successful response"
						}
					}
				}
			}
		}
  	}'
	local response
	response=$(http --body POST "$SCHEMAREGISTRY_HOST/apis/registry/v2/groups/$group_id/artifacts" Content-Type:"application/json; artifactType=OPENAPI" Authorization:"bearer $token" <<<"$api_description")
	echo "$response"
	if [[ $(echo "$response" | jq -r '.status') == 401 ]]; then
		echo "Error uploading API description!"
		return 1
	else
		echo "API description uploaded successfully."
		echo "$response" | jq
	fi
	return 0
}

echo "Start test"
service_token=$(get_default_access_token $TENANT)

echo "INFO - groups lookup with anonymous user:"
if ! test_anonymous_user; then
	exit 1
fi

echo
echo "Uploading API description as anonymous..."
if upload_api_description $GROUPID "$empty_token"; then
	echo "Upload should have failed"
	exit 1
fi

echo
echo "Test jwt auth:"
if ! test_jwt_auth "$service_token"; then
	exit 1
fi

echo "Uploading API description..."
if ! upload_api_description $GROUPID "$service_token"; then
	echo "Upload failed"
	exit 1
fi

echo "Finished test sucessfully."
