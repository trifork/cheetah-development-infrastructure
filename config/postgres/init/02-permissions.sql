-- Permission roles mirror the OpenSearch role mapping; they cannot log in.
-- OAuth client roles from 01-roles.sql are granted them below.
\connect "cheetah-postgres"

CREATE ROLE default_read NOLOGIN;
CREATE ROLE default_write NOLOGIN;
CREATE ROLE default_delete NOLOGIN;
CREATE ROLE all_access NOLOGIN;

GRANT USAGE ON SCHEMA public TO default_read, default_write, default_delete, all_access;

-- Default privileges cover every table created later by init scripts or pgAdmin.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin, "default-create" IN SCHEMA public
    GRANT SELECT ON TABLES TO default_read;
-- Upserts read existing rows; writes need SELECT as well.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin, "default-create" IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE ON TABLES TO default_write;
-- PostgreSQL cannot GRANT DROP; TRUNCATE is the closest delete model.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin, "default-create" IN SCHEMA public
    GRANT DELETE, TRUNCATE ON TABLES TO default_delete;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, pgadmin, "default-create" IN SCHEMA public
    GRANT ALL ON TABLES TO all_access

-- Same mapping as the OpenSearch client roles in local-development.json.
GRANT all_access TO "default-access";
GRANT default_write, default_delete TO "default-write";
GRANT default_read TO "default-read";
