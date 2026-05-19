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
* **postgres-validator-build** init container that provisions `pg_oidc_validator.so` (upstream Percona) into a shared volume on first boot. Prefers the upstream prebuilt `.deb`; falls back to compiling from source.
* **PostgreSQL 18** OAuth-protected PostgreSQL database. Mounts the validator `.so` read-only from the shared volume.
* **pgAdmin** (opt-in via the `pgadmin` profile) GUI for browsing the database. Uses a scoped scram-sha-256 carve-out because pgAdmin can't drive libpq's device-flow OAuth (see `config/postgres/pg_hba.conf`).

### Running PostgreSQL and its associated services

Run:

```bash
docker compose --profile=postgres up -d
```

To also run pgAdmin (opt-in):

```bash
docker compose --profile=postgres --profile=pgadmin up -d
# then visit http://localhost:5050  (login: pgadmin4@pgadmin.org / admin)
```

The validator init container exits successfully on first start. To force a re-fetch (e.g. after upstream releases a new validator), drop the named volume:

```bash
docker compose --profile=postgres down -v
```

### Authentication

PostgreSQL network authentication is OAuth-only for services. The `pgadmin` role is the single exception: it uses scram-sha-256 password auth via a scoped rule in `pg_hba.conf` so pgAdmin (which has no device-flow UI today) can still connect.

- OAuth issuer: `https://keycloak:8443/realms/local-development`
- OAuth scope: `postgres`
- pgAdmin role/password: `pgadmin` / `pgadmin-password` (see `config/pgadmin/pgpass`)

The issuer hostname is `keycloak` (the docker-network DNS name), so in-cluster services can fetch OIDC discovery directly via `keycloak:8443`. The Keycloak admin console remains reachable at `https://localhost:8443/admin` from the host (see `KC_HOSTNAME_ADMIN` in `docker-compose/keycloak.yaml`).

The Keycloak HTTPS cert is self-signed (`config/keycloak/certs/keycloak.pem`); your browser will warn on first visit — accept the cert. The cert is generated automatically on first `up` by the `keycloak-cert-init` container (no openssl required on the host, works on Windows). To regenerate, delete the two `.pem` files in `config/keycloak/certs/` and `up` again. The postgres container imports this cert as a trusted CA at startup so the validator's HTTPS fetch of `keycloak:8443` works.

#### Host-side psql

To run `psql` from the host against the OAuth-protected listener, you need two one-time setup steps:

1. Add `127.0.0.1 keycloak` to `/etc/hosts` (so libpq can reach `keycloak:8443` during the OAuth device flow).
2. Trust `config/keycloak/certs/keycloak.pem` — either add it to your system CA store, or export `SSL_CERT_FILE=$(pwd)/config/keycloak/certs/keycloak.pem`.

Then (requires PostgreSQL 18 client + `libpq-oauth`):

```bash
psql 'host=localhost port=5432 dbname=app user=default-access oauth_issuer=https://keycloak:8443/realms/local-development oauth_client_id=default-access'
```

The validator maps the JWT `client_id` claim to a PostgreSQL role, so `user=` must match the Keycloak client_id (`default-access`, `default-read`, `default-write` — see `config/postgres/init/01-roles.sql`).

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

- Admin console (from the host): https://localhost:8443/admin (`KC_HOSTNAME_ADMIN`)
- OpenID Endpoint Configuration (in-cluster, HTTPS): https://keycloak:8443/realms/local-development/.well-known/openid-configuration
- OpenID Endpoint Configuration (in-cluster, HTTP backchannel): http://keycloak:1852/realms/local-development/.well-known/openid-configuration
- Token Endpoint (in-cluster, HTTP backchannel): http://keycloak:1852/realms/local-development/protocol/openid-connect/token

> Note: JWT `iss` claim on every token is `https://keycloak:8443/realms/local-development` (set by `KC_HOSTNAME`), regardless of which hostname or port the token request hit. Services that validate `iss` (schema-registry, opensearch, postgres) all expect that string.

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

