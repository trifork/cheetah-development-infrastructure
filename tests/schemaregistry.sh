#!/bin/bash

set -euo pipefail

sr_url="http://schema-registry:8080"
TENANT=1
GROUPID=124
empty_token=""

function get_default_access_token() {
  local tenant=$1
  local response

  response=$(http --check-status --ignore-stdin  --follow --all --form POST 'http://cheetahoauthsimulator:80/oauth2/token' \
    accept:'*/*' \
    Content-Type:'application/x-www-form-urlencoded' \
    cache-control:'no-cache' \
    grant_type=client_credentials scope= client_id="$tenant" client_secret=123
  )
  local access_token=$(printf '%s' "$response" | jq -r '.access_token')
  echo "$access_token"
}

function test_anonymous_user() {
  if ! http --check-status --ignore-stdin "$sr_url/apis/registry/v2/users/me" cache-control:'no-cache'; then
    echo "ERROR - Anonymous readonly not allowed"
    return 1
  fi
  return 0
}

function test_jwt_auth() {
  local token=$1
  local response
  response=$(http --check-status --ignore-stdin "$sr_url/apis/registry/v2/users/me"  Authorization:"bearer $token")
  echo "$response"
  if [[ $response =~ "error_code" ]]; then
    echo "ERROR - Authorized access using jwt failed"
    return 1
  fi
  return 0
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
  response=$(http --body POST "$sr_url/apis/registry/v2/groups/$group_id/artifacts" Content-Type:"application/json; artifactType=OPENAPI" Authorization:"bearer $token" <<< "$api_description")
  echo "$response"
  if [[ ${#response} == 0 ]]; then
    echo "Error uploading API description!"
    return 1
  else
    echo "API description uploaded successfully."
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
  exit 1
fi

echo "finished test sucessfully"