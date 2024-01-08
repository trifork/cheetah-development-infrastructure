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
1. Run `docker network create cheetah-infrastructure`

### Security model

The development infrastructure follows the [Reference Security Model](https://docs.cheetah.trifork.dev/reference/security).  
For local development we are using [Keycloak](https://www.keycloak.org/) inside `docker-compose/keycloak.yaml` as a local IDP.

See sections below for details on security model configuration.

## Kafka

The kafka setup consists of different services:

- **kafka** - Strimzi Kafka with the [Cheetah Kafka Authorizer](https://github.com/trifork/cheetah-infrastructure-utils-kafka)
- **zookeeper** - Strimzi Zookeeper
- **redpanda** - A Console provides a user interface to manage multiple Kafka connect clusters. <https://docs.redpanda.com/docs/manage/console/>
- **kafka-setup** - A bash script which sets up a Kafka User for redpanda to use when connecting to Kafka, as well as some predefined topics. The topics to be created are determined by the environment variable INITIAL_KAFKA_TOPICS, which can be set in the `.env` file or overritten in your local environment. 
- **schema-registry** - [Schema registry](https://www.apicur.io/registry/docs/apicurio-registry/2.4.x/index.html)
- **kafka-minion** - [Kafka Prometheus exporter](https://github.com/cloudhut/kminion)

### Running Kafka and its associated services

Run:

```bash
docker compose --profile=kafka --profile=oauth --profile=schemaregistry --profile=redpanda up -d
```

When all of the services are running, you can go to:

- <http://localhost:9898/topics> to see the different topics in redpanda.
- <http://localhost:8081> to see the schema-registry UI.
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

When working locally, you can use `admin:admin` user and query OpenSearch like this:

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

## List of all profiles in docker compose

**List of profiles:**

- full
- core
- kafka
- opensearch
- observability

Here is further explanation on what each profile starts.

|  Images / profiles   | full  | core  | kafka | opensearch | observability |
| :------------------: | :---: | :---: | :---: | :--------: | :-----------: |
|        Kafka         |   x   |   x   |   x   |            |               |
|       Keycloak       |   x   |   x   |   x   |     x      |               |
|   Redpanda console   |   x   |       |   x   |            |               |
|   Schema registry    |   x   |   x   |   x   |            |               |
|      Opensearch      |   x   |   x   |       |     x      |               |
| Opensearch dashboard |   x   |       |       |     x      |               |
| Opensearch configurer|   x   |   x   |   x   |     x      |       x       |
|      Prometheus      |   x   |       |       |            |       x       |
|       Grafana        |   x   |       |       |            |       x       |

## Keycloak

Keycloak is used as a local identity provider, to be able to mimic a production security model with service to service authentication.

### Useful urls:

- OpenID Endpoint Configuration: http://localhost:1852/realms/local-development/.well-known/openid-configuration
- Token Endpoint http://localhost:1852/realms/local-development/protocol/openid-connect/token 

### Default clients:

A set of default clients have been defined which covers most common usecases.

All roles are mapped to the `roles` claim in the JWT. This configuration is defined in [local-development.json](./config/keycloak/local-development.json) and is applied to keycloak using the `keycloak-setup` service.
To modify the configuration either go to the [admin console](http://localhost:1852/admin) (Username: `admin` Password: `admin`) or edit the `local-development.json` following this [guide](./config/keycloak/setup.md)

- Default access
     * Description: Read and write access to all data Kafka, OpenSearch and Schema registry
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
- Default write
     * Description: Write access to all data in Kafka, OpenSearch and Schema registry
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
          - `schema-registry`
               * Roles:
                    - `sr-producer`
- Default read
     * Description: Read access to all data in Kafka, OpenSearch and Schema registry
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
- Users
     * Description: User login via browser such as OpenSearch Dashboard (See [Users](#users) for user details)
     * client_id: `users`
     * client_secret: `users-secret`
     * default_scopes: [ ] 
     * optional_scopes:
          - `kafka`
          - `opensearch`
          - `schema-registry`
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
