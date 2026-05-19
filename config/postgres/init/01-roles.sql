CREATE DATABASE app;

CREATE ROLE "default-access" LOGIN;
CREATE ROLE "default-read" LOGIN;
CREATE ROLE "default-write" LOGIN;

-- pgadmin is the one exception to OAuth-only: a dedicated role using
-- scram-sha-256 password auth, via the scoped rule in pg_hba.conf.
-- SUPERUSER so the dev tool can create tables/schemas/extensions freely.
CREATE ROLE pgadmin LOGIN PASSWORD 'admin' SUPERUSER;

GRANT CONNECT ON DATABASE app TO "default-access";
GRANT CONNECT ON DATABASE app TO "default-read";
GRANT CONNECT ON DATABASE app TO "default-write";
GRANT CONNECT ON DATABASE app TO pgadmin;
