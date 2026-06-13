CREATE DATABASE "cheetah-postgres";

CREATE ROLE "default-access" LOGIN;
CREATE ROLE "default-read" LOGIN;
CREATE ROLE "default-write" LOGIN;
CREATE ROLE "default-create" LOGIN;

-- pgadmin is the one exception to OAuth-only: a dedicated role using
-- scram-sha-256 password auth, via the scoped rule in pg_hba.conf.
-- SUPERUSER so the dev tool can create tables/schemas/extensions freely.
CREATE ROLE pgadmin LOGIN PASSWORD 'admin' SUPERUSER;

GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-access";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-read";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-write";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-create";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO pgadmin;

-- Schema-level privileges live inside the target database, so switch into it
-- (init scripts otherwise run against the default "postgres" database).
\connect "cheetah-postgres"
GRANT CREATE ON SCHEMA public TO "default-create";
