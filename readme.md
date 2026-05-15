# Cheetah development infrastructure

This repository is used to setup infrastructure when developing locally using Kafka/OpenSearch.

The repository consists of a set of docker-compose files which are all referenced in the [.env](.env) file. This allows invoking `docker compose up <service-name>` on a service in any of the docker-compose files, from the root of the repository.

See also: <https://docs.cheetah.trifork.dev/reference/development-infrastructure>

## Start infrastructure

```bash
docker compose up --quiet-pull
```

## Prerequisites

1. Follow: <https://docs.cheetah.trifork.dev/getting-started/guided-tour/prerequisites#run-standard-jobs>

## Resource requirements

The infrastructure requires a lot of resources, especially memory when running all services at once.

Here is some basic profiling done while running through WSL2 with 16GB RAM:

```sh
# See if your docker supports memory limits
docker info --format '{{json .MemoryLimit}}'
# Get total memory for docker
docker info --format '{{json .MemTotal}}' | numfmt --from=auto --to=iec
# Get total CPUs for docker
docker info --format '{{json .NCPU}}'
```

|  Profile   | MEM USAGE / LIMIT |
| :--------: | :---------------: |
|    core    |   2.4GB / 4.4GB   |
|   kafka    |   1.3GB / 2.2GB   |
| opensearch |   1.9GB / 2.9GB   |
|    full    |   2.9GB / 5.2GB   |

Estimated requirements:

|   Profile   | CPUs  | Docker available memory (RAM) | Disk space (Images) |
| :---------: | :---: | :---------------------------: | :-----------------: |
|   Minimum   |   2   |              4GB              |       >6.6GB        |
| Recommended |   8   |              8GB              |        >20GB        |
|    Best     |  16   |             16GB              |        >40GB        |

### Security model

The development infrastructure follows the [Reference Security Model](https://docs.cheetah.trifork.dev/reference/security).  
For local development we are using [Keycloak](https://www.keycloak.org/) inside `docker-compose/keycloak.yaml` as a local IDP.

See sections below for details on security model configuration.

## Kafka

The kafka setup consists of different services:

- **kafka** - Strimzi Kafka with the [Cheetah Kafka Authorizer](https://github.com/trifork/cheetah-infrastructure-utils-kafka)
- **redpanda** - A Console provides a user interface to manage multiple Kafka connect clusters. <https://docs.redpanda.com/docs/manage/console/>
- **kafka-setup** - A bash script which sets up a Kafka User for redpanda to use when connecting to Kafka, as well as some predefined topics. The topics to be created are determined by the environment variable INITIAL_KAFKA_TOPICS, which can be set in the `.env` file or overritten in your local environment. 
- **schema-registry** - [Schema registry](https://www.apicur.io/registry/docs/apicurio-registry/2.5.x/index.html)
- **kafka-minion** - [Kafka Prometheus exporter](https://github.com/cloudhut/kminion)

### Running Kafka and its associated services

Run:

```bash
docker compose --profile=kafka --profile=oauth --profile=schemaregistry --profile=redpanda up -d
```

When all of the services are running, you can go to:

- <http://localhost:9898/topics> to see the different topics in redpanda.
- <http://localhost:8081/apis> to the the schema-registry api documentation

### Listeners

5 different listeners is setup for Kafka on different internal and external ports (see [server.properties](/config/kafka/server.properties) for the configuration):

- `localhost:9092` - Used for connecting to kafka with OAuth2 authentication from outside the docker environment.
- `localhost:9093` - Used for connecting to kafka without authentication from outside the docker environment.
- `kafka:19092` - Used for connecting to kafka with OAuth2 authentication from a docker container in the `cheetah-infrastructure` docker network.
- `kafka:19093` - Used for connecting to kafka without authentication from a docker container in the `cheetah-infrastructure` docker network.
- `kafka:19094` - Only used by Redpanda, since it does not support Oauth2.

### Authentication

To require Oauth2 authentication when connecting to kafka, you can remove `;User:ANONYMOUS` from the `super.users` property in [server.properties](/config/kafka/server.properties).  
This will cause all connections from unauthenticated sources to be rejected by `CheetahKafkaAuthorizer`.

## OpenSearch

The OpenSearch setup consists of different services:

- **OpenSearch** - OpenSearch data storage solution
- **OpenSearch-Dashboard** - Dashboard solution for interacting with OpenSearch API
- **OpenSearch Configurer** - Uses [OpenSearch Template Configuration Script](https://github.com/trifork/cheetah-infrastructure-utils-opensearch) to setup Index Templates and more.

Files placed in any subdirectory of [config/opensearch-configurer/](config/opensearch-configurer/) are automatically applied to the OpenSearch instance.

### Running OpenSearch and its associated services

Run:

```bash
docker compose --profile=opensearch --profile=opensearch_dashboard up -d
```

When all of the services are running, you can go to:

- <http://localhost:9200/> OpenSearch
- <http://localhost:5602> to see the dashboard UI
- <http://localhost:9200/_cat/indices> to see all current indices

### Authentication

Services should connect using the OAuth2 protocol.  
You can choose to set `DISABLE_SECURITY_DASHBOARDS_PLUGIN=true` and `DISABLE_SECURITY_PLUGIN=true` to disable security completely.

#### Basic auth access

**Note:** OpenSearch has anonymous access enabled by default, but the anonymous user has no permissions. Browsers won't prompt for credentials automatically.

**For browser access**, use a browser extension or tool that supports basic authentication, or use the OpenSearch Dashboard at <http://localhost:5602> instead.

**For API/command line access**, use curl with the `admin:admin` credentials:

```sh
curl -k -s -u "admin:admin" http://localhost:9200/
curl -k -s -u "admin:admin" http://localhost:9200/_cat/indices
```

Or set the OPENSEARCH_URL variable:

```sh
curl -k -s -u "admin:admin" $OPENSEARCH_URL/_cat/indices
```

#### OAuth2 token

If you do not want to use basicauth locally, you can get a token using this curl command:

```sh
ACCESS_TOKEN=$(curl -s -X POST $OPENSEARCH_TOKEN_URL \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials&client_id=$OPENSEARCH_CLIENT_ID&client_secret=$OPENSEARCH_CLIENT_SECRET&scope=$OPENSEARCH_SCOPE" \
     | jq -r '.access_token')
     #| grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')
```

And query OpenSearch like this:

```sh
curl -k -s -H "Authorization: Bearer $ACCESS_TOKEN" $OPENSEARCH_URL/_cat/indices
```

## PostgreSQL

The PostgreSQL setup consists of different services:
* **PostgreSQL 18** OAuth-protected PostgreSQL database. Bind-mounts the prebuilt `pg_oidc_validator.so` checked in at `config/postgres/validator/`.
* **PgAdmin** GUI container for database administration.
* **postgres-validator-build** (opt-in, profile `validator-build`) one-shot helper to rebuild `pg_oidc_validator.so` from a sibling checkout of the [`MarkBogelund/pg_oidc_validator`](https://github.com/MarkBogelund/pg_oidc_validator) fork. The committed `.so` is the source of truth until we publish a real distribution channel.

### Running PostgreSQL and its associated services

Run:

```bash
docker compose --profile=postgres up -d
```

### Rebuilding the OAuth validator

Only needed when the validator fork changes. Requires `MarkBogelund/pg_oidc_validator` checked out as a sibling of this repo (`../pg_oidc_validator`). Then:

```bash
docker compose --profile=validator-build up postgres-validator-build
```

This compiles the fork against `postgres:18.3-trixie` and overwrites `config/postgres/validator/pg_oidc_validator.so`. Commit the updated `.so`.

When all of the services are running, you can go to:

- <http://localhost:5050> to see the PgAdmin UI

### Authentication

PostgreSQL network authentication is configured to use OAuth only.

- Basic/password auth is disabled for host connections.
- OAuth issuer: `https://localhost:8443/realms/local-development`
- OAuth scope: `postgres`

The Keycloak HTTPS cert is self-signed (`config/keycloak/certs/keycloak.pem`); your browser will warn on first visit — accept the cert. To regenerate the cert, run `bash config/keycloak/certs/generate-certs.sh`.

Example interactive OAuth login with `psql` (requires PostgreSQL 18 client + `libpq-oauth`):

```bash
psql 'host=localhost port=5432 dbname=app user=developer oauth_issuer=https://localhost:8443/realms/local-development oauth_client_id=users'
```

## List of all profiles in docker compose

**List of profiles:**

- full
- core
- kafka
- opensearch
- observability
- postgres

Here is further explanation on what each profile starts.

|   Images / profiles   | kafka-core | opensearch-core | schema-registry-core | core  | kafka | opensearch | observability | postgres | full  |
| :-------------------: | :--------: | :-------------: | :------------------: | :---: | :---: | :--------: | :-----------: | :-------: | :---: |
|       Keycloak        |     x      |        x        |          x           |   x   |   x   |     x      |       x       |           |   x   |
|         Kafka         |     x      |                 |          x           |   x   |   x   |            |       x       |           |   x   |
|   Redpanda console    |            |                 |                      |       |   x   |            |               |           |   x   |
|      Opensearch       |            |        x        |                      |   x   |       |     x      |               |           |   x   |
| Opensearch dashboard  |            |                 |                      |       |       |     x      |               |           |   x   |
| Opensearch configurer |            |        x        |                      |   x   |       |     x      |               |           |   x   |
|    Schema registry    |            |                 |          x           |   x   |   x   |            |               |           |   x   |
|      Prometheus       |            |                 |                      |       |       |            |       x       |           |   x   |
|        Grafana        |            |                 |                      |       |       |            |       x       |           |   x   |
|      PostgreSQL       |            |                 |                      |       |       |            |               |    x     |       |

## Keycloak

Keycloak is used as a local identity provider, to be able to mimic a production security model with service to service authentication.

### Useful urls:

- OpenID Endpoint Configuration (HTTPS, used by browsers and `libpq`): https://localhost:8443/realms/local-development/.well-known/openid-configuration
- OpenID Endpoint Configuration (HTTP backchannel for service-to-service): http://keycloak:1852/realms/local-development/.well-known/openid-configuration
- Token Endpoint (HTTP backchannel): http://keycloak:1852/realms/local-development/protocol/openid-connect/token

> Note: JWT `iss` claim on every token is `https://localhost:8443/realms/local-development`, regardless of which port the token request hit. Services that validate `iss` (schema-registry, opensearch, postgres) are configured to expect that string. 

### Default clients:

A set of default clients have been defined which covers most common usecases.

All roles are mapped to the `roles` claim in the JWT. This configuration is defined in [local-development.json](./config/keycloak/local-development.json) and is applied to keycloak using the `keycloak-setup` service.
To modify the configuration either go to the [admin console](http://localhost:1852/admin) (Username: `admin` Password: `admin`) or edit the `local-development.json` following this [guide](./config/keycloak/setup.md)

- Default access
     * Description: Read and write access to all data Kafka, OpenSearch, Schema registry and PostgreSQL
     * client_id: `default-access`
     * client_secret: `default-access-secret`
     * default_scopes: [ ] 
     * optional_scopes:
          - `kafka`
               * Roles:
                    - `Kafka_*_all`
          - `opensearch`
               * Roles:
                    - `opensearch_default_access`
          - `schema-registry`
               * Roles:
                    - `sr-producer`
          - `postgres`
               * Roles:
                    - `postgres_access`
- Default write
     * Description: Write access to all data in Kafka, OpenSearch, Schema registry and PostgreSQL
     * client_id: `default-write`
     * client_secret: `default-write-secret`
     * default_scopes: [ ] 
     * optional_scopes:
          - `kafka`
               * Roles:
                    - `Kafka_*_write`
          - `opensearch`
               * Roles:
                    - `opensearch_default_write`
                    - `opensearch_default_delete`
          - `schema-registry`
               * Roles:
                    - `sr-producer`
          - `postgres`
               * Roles:
                    - `postgres_access`
- Default read
     * Description: Read access to all data in Kafka, OpenSearch and PostgreSQL (plus schema-registry producer role where configured)
     * client_id: `default-read`
     * client_secret: `default-read-secret`
     * default_scopes: [ ] 
     * optional_scopes:
          - `kafka`
               * Roles:
                    - `Kafka_*_read`
          - `opensearch`
               * Roles:
                    - `opensearch_default_read`
          - `postgres`
               * Roles:
                    - `postgres_access`
- Users
     * Description: User login via browser such as OpenSearch Dashboard (See [Users](#users) for user details)
     * client_id: `users`
     * client_secret: `users-secret`
     * default_scopes: [ ] 
     * optional_scopes:
          - `kafka`
          - `opensearch`
          - `schema-registry`
          - `postgres`
- Custom client
     * Description: A custom client which can be configured using Environment variables. Useful for pipelines where services require custom roles.
     * client_id: $DEMO_CLIENT_NAME
     * client_secret: $DEMO_CLIENT_SECRET
     * default_scopes:
          -  `custom-client`
               * Roles: $DEMO_CLIENT_ROLES - Should be a comma separated list e.g. (`my_view_role,my_edit_role,my_admin_role`)
     * optional_scopes: [ ]

### Users:
- developer
     * Username: `developer`
     * Password: `developer`
     * Roles:
          - `opensearch_developer`
          - `opensearch_default_read`
          - `Kafka_*_all`
          - `sr-producer`
          - `postgres_access`

