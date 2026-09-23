-- Permission roles, named and scoped like the OpenSearch roles in
-- config/opensearch/security/roles.yml. They cannot log in. The OAuth client
-- roles from 01-roles.sql are granted them below, like roles_mapping.yml and
-- the Keycloak client roles do for OpenSearch.
\connect "cheetah-postgres"

CREATE ROLE default_read NOLOGIN;
CREATE ROLE default_write NOLOGIN;
CREATE ROLE default_delete NOLOGIN;
CREATE ROLE all_access NOLOGIN;

GRANT USAGE ON SCHEMA public TO default_read, default_write, default_delete, all_access;

-- Default privileges cover every table created later by the init scripts
-- (postgres) or in pgAdmin (pgadmin), like the "*" index patterns in roles.yml.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin IN SCHEMA public
    GRANT SELECT ON TABLES TO default_read;
-- An upsert reads the existing row, so writing needs SELECT as well.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE ON TABLES TO default_write;
-- DROP cannot be granted in PostgreSQL. Emptying a table is the closest to deleting an index.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin IN SCHEMA public
    GRANT DELETE, TRUNCATE ON TABLES TO default_delete;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin IN SCHEMA public
    GRANT ALL ON TABLES TO all_access;

-- Same mapping as the opensearch client roles in config/keycloak/local-development.json
GRANT all_access TO "default-access";
GRANT default_write, default_delete TO "default-write";
GRANT default_read TO "default-read";
