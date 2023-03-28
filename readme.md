<https://docs.cheetah.trifork.dev/reference/development-infrastructure>

# Cheetah development infrastructure

This repository is used to setup infrastructure when developing locally using Kafka/Opensearch

The repository consists of a set of docker-compose files which are all referenced in the [.env](.env) file. This allows invoking `docker compose up <service-name>` on a service in any of the docker-compose files, from the root of the repository.

## Prerequisites

1. Follow: https://docs.cheetah.trifork.dev/getting-started/guided-tour/prerequisites#run-standard-jobs
1. Run `docker network create cheetah-infrastructure`

## Kafka

The kafka setup consists of different services:

- **kafka** - Strimzi Kafka with the [Cheetah Kafka Authorizer](https://github.com/trifork/cheetah-infrastructure-utils-kafka)
- **zookeeper** - Strimzi Zookeeper
- **redpanda** - A Console provides a user interface to manage multiple Kafka connect clusters. https://docs.redpanda.com/docs/manage/console/
- **kafka-setup** - A bash script which sets up a Kafka User for redpanda to use when connecting to Kafka, as well as some predefined topics.
- **schema-registry** - [Schema registry](https://www.apicur.io/registry/docs/apicurio-registry/2.4.x/index.html)
- **kafka-minion** - [Kafka Prometheus exporter](https://github.com/cloudhut/kminion)

### Running Kafka and its associated services

Run:

```
docker compose --profile=kafka up -d
```

When all of the services are running, you can go to:

- http://localhost:9898/topics to see the different topics in redpanda.
- http://localhost:8081 to see the schema-registry UI.
- http://localhost:8081/apis to the the schema-registry api documentation

### Listeners:

5 different listeners is setup for Kafka on different internal and external ports (see [server.properties](/config/kafka/server.properties) for the configuration):

- `localhost:9092` - Used for connecting to kafka with Oauth2 authentication from outside the docker environment.
- `localhost:9093` - Used for connecting to kafka without authentication from outside the docker environment.
- `kafka:19092` - Used for connecting to kafka with Oauth2 authentication from a docker container in the `cheetah-infrastructure` docker network.
- `kafka:19093` - Used for connecting to kafka without authentication from a docker container in the `cheetah-infrastructure` docker network.
- `kafka:19094` - Only used by Redpanda, since it does not support Oauth2.

To require Oauth2 authentication when connecting to kafka, you can remove `;User:ANONYMOUS` from the `super.users` property in [server.properties](/config/kafka/server.properties). This will cause all connections from unauthenticated sources to be rejected by `CheetahKafkaAuthorizer`.
