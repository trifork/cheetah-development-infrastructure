CREATE DATABASE "cheetah-postgres";

CREATE ROLE "default-access" LOGIN;
CREATE ROLE "default-read" LOGIN;
CREATE ROLE "default-write" LOGIN;
CREATE ROLE "default-create" LOGIN;

-- pgAdmin is the OAuth exception: dedicated login with scram-sha-256.
-- SUPERUSER lets the dev tool manage schemas, tables, and extensions.
CREATE ROLE pgadmin LOGIN PASSWORD 'admin' SUPERUSER;

GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-access";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-read";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-write";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO "default-create";
GRANT CONNECT ON DATABASE "cheetah-postgres" TO pgadmin;

-- Switch to the app database; init scripts otherwise hit postgres.
\connect "cheetah-postgres"
GRANT CREATE ON SCHEMA public TO "default-create";
