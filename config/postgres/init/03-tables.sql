-- Jobs write to PostgreSQL; tables are created up front like OpenSearch templates.
-- Privileges come from 02-permissions.sql; columns match Kafka message fields.
\connect "cheetah-postgres"

-- cheetah-app-jobs-golang postgresstoragejob.
CREATE TABLE public.data_centric (
    kafka_key   text PRIMARY KEY,
    "uuid"      text,
    "deviceId"  text,
    "timestamp" text,
    "value"     bigint
);
