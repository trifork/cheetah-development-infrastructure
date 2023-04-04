#!/bin/bash

set -euo pipefail

#
# Test Redpanda is connected to kafka
#

echo "INFO - Testing if Redpanda has brokers connected:"
curl -s --fail "http://redpanda:8080/admin/startup"
if ! curl -s --fail-with-body -k "http://redpanda:8080/api/cluster" | jq -e -r ".clusterInfo.brokers | length >= 0"; then
  echo
  echo "ERROR - Brokers not detected for RedPanda console"
  exit 1
fi