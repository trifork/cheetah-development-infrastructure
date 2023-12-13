## Adding a new set of client credentials

To add a new set of client credentials you need to add:
- A client under `clients` with the following structure:
    ```
      {
        "clientId": "<your-client-id>",
        "name": "<your-client-name>",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "<your-secret>",
        "serviceAccountsEnabled": true,
        "publicClient": false,
        "optionalClientScopes": [
            "<your-optional-client-scope1>",
            "<your-optional-client-scope2>",
            ...
        ],
        "defaultClientScopes": [
            "<your-default-client-scope1>",
            "<your-default-client-scope2>",
            ...
        ]
      }

- A user under `users` with the following structure:
    ```
      {
        "username": "service-account-<your-client-id>",
        "enabled": true,
        "serviceAccountClientId": "<your-client-id>",
        "clientRoles": {
          "<scope-for-roles-m-n>": [
            "<role-m>",
            ...
            "<role-n>
          ],
          "<scope-for-roles-i-j>": [
            "<role-i>"
            ...
            "<role-j>"
          ]
          ...
        }
      }
- If a new role has been added to an existing scope:
    - Add the role to `roles.client.<existing-scope>`
- If a new role has been added to a new scope:
    - Add the role to `roles.client.<new-scope>`
    - Add a client with the following structure under `clients`:
        ```
        {
            "clientId": "<new-scope>",
            "name": "<new-scope>"
        }
        ```
    - Add a scope mapper with the following structure under `clientScopes`:
        ```
        {
            "name": "<new-scope>",
            "protocol": "openid-connect",
            "protocolMappers": [
                {
                    "name": "client roles",
                    "protocol": "openid-connect",
                    "protocolMapper": "oidc-usermodel-client-role-mapper",
                    "consentRequired": false,
                    "config": {
                        "multivalued": "true",
                        "access.token.claim": "true",
                        "id.token.claim": "true",
                        "claim.name": "roles",
                        "jsonType.label": "String",
                        "usermodel.clientRoleMapping.clientId": "<new-scope>"
                    }
                }
            ]
        }
