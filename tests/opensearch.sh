#!/bin/bash

set -euo pipefail

# Only start opensearch
#docker compose --profile=oauth --profile=opensearch up --quiet-pull --force-recreate 

function get_default_access_token() {
  local tenant=$1
  local response
  local access_token
  response=$(curl --fail -s -X 'POST' \
    'http://localhost:1752/oauth2/token' \
    -H 'accept: */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'cache-control: no-cache' \
    -d "grant_type=client_credentials&scope=&client_id=$tenant&client_secret="
   )
  access_token=$(printf '%s' "$response" | jq -r '.access_token')
  echo "$access_token"
}

function get_customaccess_token() {
  local tenant=$1
  local roles=$2 # backend roles
  local response
  local access_token
  response=$(curl -s -X 'POST' \
    'http://localhost:1752/oauth2/customtoken' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -H 'cache-control: no-cache' \
    -d "{
    \"clientId\": \"$tenant\",
    \"claims\": {
      \"osroles\": \"$roles\",
      \"osuser\": \"hest\"
    },
    \"expiresInMinutes\": 120
  }")
  access_token=$(printf '%s' "$response" | jq -r '.access_token')
  echo "$access_token"
}


TENANT=1
service_token=$(get_default_access_token $TENANT)
admin_token=$(get_customaccess_token $TENANT 'admin')

# Test token
curl -X GET "http://localhost:9229/_cat/indices" -H "Authorization: bearer $(printf '%s' "$service_token")"
echo "OAuth2 works"

# Test basic auth
curl  -X GET "http://admin:admin@localhost:9229/_cat/indices" 
echo "Basic auth works"
