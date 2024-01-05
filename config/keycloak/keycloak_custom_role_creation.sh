#!/bin/bash
echo "Running keycloak_custom_role_creation.sh"

set -euo pipefail

# Input and output file names
input_file="$1"
output_file="$2"

# Split the demo_client_roles string into an array
IFS=',' read -ra roles_array <<<"$DEMO_CLIENT_ROLES"

# Build the roles_definition_substitution string for $(env:DEMO_ROLES_DEFINITION)
roles_definition_substitution=""
for role in "${roles_array[@]}"; do
    roles_definition_substitution+="{\"name\":\"$role\"},"
done
# Remove the trailing comma
roles_definition_substitution="${roles_definition_substitution%,}"

# Build the client_roles_substitution string for $(env:DEMO_CLIENT_ROLES) using a loop
client_roles_substitution="["
for role in "${roles_array[@]}"; do
    client_roles_substitution+="\"$role\","
done
# Remove the trailing comma
client_roles_substitution="${client_roles_substitution%,}"
client_roles_substitution+="]"

# Perform substitutions and save to output file
sed -e "s/\$(env:DEMO_ROLES_DEFINITION)/$roles_definition_substitution/g" \
    -e "s/\$(env:DEMO_CLIENT_NAME)/$DEMO_CLIENT_NAME/g" \
    -e "s/\$(env:DEMO_CLIENT_SECRET)/$DEMO_CLIENT_SECRET/g" \
    -e "s/\$(env:DEMO_CLIENT_ROLES)/$client_roles_substitution/g" \
    "$input_file" > "$output_file"