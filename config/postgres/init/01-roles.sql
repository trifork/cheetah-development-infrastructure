-- `app` is created by docker-entrypoint.sh via POSTGRES_DB.
CREATE ROLE "default-access" LOGIN;
CREATE ROLE "default-read" LOGIN;
CREATE ROLE "default-write" LOGIN;

GRANT CONNECT ON DATABASE app TO "default-access";
GRANT CONNECT ON DATABASE app TO "default-read";
GRANT CONNECT ON DATABASE app TO "default-write";
