#!/bin/bash

set -euo pipefail

#
# Test authentication using JWT
#

function get_default_access_token() {
  local tenant=$1
  local response
  local access_token
  response=$(curl --fail -s -X 'POST' \
    'http://cheetahoauthsimulator:80/oauth2/token' \
    -H 'accept: */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'cache-control: no-cache' \
    -d "grant_type=client_credentials&scope=&client_id=$tenant&client_secret="
   )
  access_token=$(printf '%s' "$response" | jq -r '.access_token')
  echo "$access_token"
}

TENANT=1
GROUPID=123
cache_header="cache-control: no-cache"
sr_url="http://schema-registry:8080"

service_token=$(get_default_access_token $TENANT)
echo $service_token

echo "INFO - groups lookup with anonymous user:"
if ! curl -s --fail-with-body -k "$sr_url/apis/registry/v2/users/me" -H "$cache_header" ; then
  echo
  echo "ERROR - Anonymous readonly not allowed"
  exit 1
fi

echo
echo "Test jwt auth:"
response=$(curl --fail-with-body -s -X GET "$sr_url/apis/registry/v2/users/me" -H "Authorization: bearer $(printf '%s' "$service_token")")
echo $response
if [[ $response =~ "error_code" ]]; then
  echo
  echo "ERROR - Authorized access using jwt failed"
  exit 1
fi


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
}'  # Replace with your inline JSON API description

# Function to upload the artifact
echo
echo "Uploading API description..."

# Send a POST request to the registry API with cURL
response=$(curl -s -X POST -H "Content-Type: application/json; artifactType=OPENAPI" --data-binary "$API_DESCRIPTION" "$sr_url/apis/registry/v2/groups/$GROUPID/artifacts" -H "Authorization: bearer $(printf '%s' "$service_token")")

# Check the response for errors
if [[ $response =~ "error_code" ]]; then
    echo "Error uploading API description:"
    echo "$response"
else
    echo "API description uploaded successfully."
fi

