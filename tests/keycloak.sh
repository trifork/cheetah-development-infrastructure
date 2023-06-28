#!/bin/bash

set -euo pipefail

TOKEN_URL=http://localhost:9050/realms/example/protocol/openid-connect/token
CLIENT_ID=cheetahclient
CLIENT_SECRET=my-secret
SCOPE=roles

TOKEN=$(curl --fail -X POST "$TOKEN_URL" \
               -H 'Content-Type: application/x-www-form-urlencoded' \
               -d "client_id=$CLIENT_ID" \
               -d "client_secret=$CLIENT_SECRET" \
               -d 'grant_type=client_credentials' \
               -d "scope=$SCOPE" | jq -r '.access_token')

PAYLOAD=$(echo "${TOKEN}" | cut -d "." -f 2 | base64 --decode)

echo "$TOKEN"
echo "$PAYLOAD"