-- Tables for jobs that write to PostgreSQL. Jobs do not create tables themselves,
-- like the index templates in config/opensearch-configurer/ set up indices up front.
-- Privileges come from the default privileges in 02-permissions.sql.
\connect "cheetah-postgres"

-- cheetah-app-jobs-golang postgresstoragejob: the compose service and local runs
CREATE TABLE public.data_centric (
    id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kafka_key   text,
    group_name  text,
    event_time  timestamptz,
    payload     jsonb       NOT NULL,
    ingested_at timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT data_centric_kafka_key_key UNIQUE (kafka_key)
);
CREATE INDEX data_centric_group_name_event_time_idx ON public.data_centric (group_name, event_time);

-- cheetah-app-jobs-golang postgresstoragejob: integration test
CREATE TABLE public.test_table_postgres_storage (
    id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kafka_key   text,
    group_name  text,
    event_time  timestamptz,
    payload     jsonb       NOT NULL,
    ingested_at timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT test_table_postgres_storage_kafka_key_key UNIQUE (kafka_key)
);
CREATE INDEX test_table_postgres_storage_group_name_event_time_idx ON public.test_table_postgres_storage (group_name, event_time);
