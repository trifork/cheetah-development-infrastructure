#!/bin/bash

# Input and output file names
input_file="local-development-pre-sub.json"
output_file="../keycloak/local-development.json"

# Define the substitutions
demo_client_roles='deviceidentity.write,deviceidentity.read'
demo_client_secret='DemoClientSecret'
demo_client_name='DemoClient'

# Split the demo_client_roles string into an array
IFS=',' read -ra roles_array <<< "$demo_client_roles"

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
    -e "s/\$(env:DEMO_CLIENT_ROLES)/$client_roles_substitution/g" \
    -e "s/\$(env:DEMO_CLIENT_SECRET)/$demo_client_secret/g" \
    -e "s/\$(env:DEMO_CLIENT_NAME)/$demo_client_name/g" \
    "$input_file" > "$output_file"

echo "Substitutions completed. Output saved to $output_file"
