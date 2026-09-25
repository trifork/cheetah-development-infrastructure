-- Tables for jobs that write to PostgreSQL. Jobs do not create tables themselves,
-- like the index templates in config/opensearch-configurer/ set up indices up front.
-- Privileges come from the default privileges in 02-permissions.sql.
--
-- Columns are the fields of the Kafka message, with the same names (quoted, as they
-- are case sensitive) and the types OpenSearch's dynamic mapping gives them:
-- string -> text, whole number -> bigint. kafka_key holds the Kafka key, like the
-- document _id in OpenSearch.
\connect "cheetah-postgres"

-- cheetah-app-jobs-golang postgresstoragejob: the compose service and local runs
CREATE TABLE public.data_centric (
    kafka_key   text PRIMARY KEY,
    "uuid"      text,
    "deviceId"  text,
    "timestamp" text,
    "value"     bigint
);

-- cheetah-app-jobs-golang postgresstoragejob: integration test
CREATE TABLE public.test_table_postgres_storage (
    kafka_key   text PRIMARY KEY,
    "uuid"      text,
    "deviceId"  text,
    "timestamp" text,
    "value"     bigint
);
