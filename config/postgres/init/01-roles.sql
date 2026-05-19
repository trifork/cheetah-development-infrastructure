CREATE DATABASE app;

CREATE ROLE "default-access" LOGIN;
CREATE ROLE "default-read" LOGIN;
CREATE ROLE "default-write" LOGIN;

-- pgadmin is the one exception to OAuth-only: a dedicated role using
-- scram-sha-256 password auth, via the scoped rule in pg_hba.conf.
CREATE ROLE pgadmin LOGIN PASSWORD 'pgadmin-password';

GRANT CONNECT ON DATABASE app TO "default-access";
GRANT CONNECT ON DATABASE app TO "default-read";
GRANT CONNECT ON DATABASE app TO "default-write";
GRANT CONNECT ON DATABASE app TO pgadmin;
