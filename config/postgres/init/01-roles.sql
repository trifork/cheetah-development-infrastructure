CREATE DATABASE app;

CREATE ROLE developer LOGIN;
CREATE ROLE "service-account-default-access" LOGIN;
CREATE ROLE "service-account-default-read" LOGIN;
CREATE ROLE "service-account-default-write" LOGIN;
CREATE ROLE "service-account-postgres" LOGIN;

GRANT CONNECT ON DATABASE app TO developer;
GRANT CONNECT ON DATABASE app TO "service-account-default-access";
GRANT CONNECT ON DATABASE app TO "service-account-default-read";
GRANT CONNECT ON DATABASE app TO "service-account-default-write";
GRANT CONNECT ON DATABASE app TO "service-account-postgres";
