#!/bin/bash

set -euo pipefail

sr_url="http://schema-registry:8080"
cache_header="cache-control: no-cache"
TENANT=1
GROUPID=123
empty_token=""

function get_default_access_token() {
  local tenant=$1
  local response=$(curl --fail -s -X 'POST' \
    'http://cheetahoauthsimulator:80/oauth2/token' \
    -H 'accept: */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'cache-control: no-cache' \
    -d "grant_type=client_credentials&scope=&client_id=$tenant&client_secret="
  )
  local access_token=$(printf '%s' "$response" | jq -r '.access_token')
  echo "$access_token"
}

function test_anonymous_user() {
  if ! curl -s --fail-with-body -k "$sr_url/apis/registry/v2/users/me" -H "$cache_header" ; then
    echo "ERROR - Anonymous readonly not allowed"
    return 1
  fi
  return 0
}

function test_jwt_auth() {
  local token=$1
  local response=$(curl -s --fail-with-body -k "$sr_url/apis/registry/v2/users/me" -H "Authorization: bearer $(printf '%s' "$token")")
  echo $response
  if [[ $response =~ "error_code" ]]; then
    echo "ERROR - Authorized access using jwt failed"
    return 1
  fi
  return 0
}

function upload_api_description() {
  local group_id=$1
  local token=$2
  local api_description=$3
  local response=$(curl -s -X POST -H "Content-Type: application/json; artifactType=OPENAPI" --data-binary "$api_description" "$sr_url/apis/registry/v2/groups/$group_id/artifacts" -H "Authorization: bearer $(printf '%s' "$token")")
  if [[ $response =~ "error_code" ]]; then
    echo "Error uploading API description:"
    echo "$response"
    return 1
  else
    echo "API description uploaded successfully."
  fi
  return 0
}

API_DESCRIPTION='{
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

service_token=$(get_default_access_token $TENANT)

echo "INFO - groups lookup with anonymous user:"
if ! test_anonymous_user; then
  exit 1
fi

echo
echo "Uploading API description as anonymous..."
if upload_api_description $GROUPID "" "$API_DESCRIPTION"; then
echo "Upload should have failed"
  exit 1
fi

echo
echo "Test jwt auth:"
if ! test_jwt_auth $service_token; then
  exit 1
fi

echo "Uploading API description..."
if ! upload_api_description $GROUPID $service_token "$API_DESCRIPTION"; then
  exit 1
fi
