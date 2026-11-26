#!/bin/sh
# Runs once, when the database volume is empty (official postgres image behaviour).
# Creates the pgvector extension and two least-privilege roles:
#   rag_reader  -> used by the API: read only
#   rag_ingest  -> used by ingestion: read and write data, no schema changes
set -eu

# Passwords are passed as psql variables (-v), never pasted into the SQL text.
# :'name' inserts a value as a correctly quoted SQL literal (no SQL injection).
# :"name" inserts it as a quoted identifier (database or role name).
psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v db="$POSTGRES_DB" \
  -v reader_pw="$DB_READER_PASSWORD" \
  -v ingest_pw="$DB_INGEST_PASSWORD" \
  <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;

-- Nobody connects to this database unless explicitly allowed.
REVOKE ALL ON DATABASE :"db" FROM PUBLIC;

CREATE ROLE rag_reader LOGIN PASSWORD :'reader_pw';
CREATE ROLE rag_ingest LOGIN PASSWORD :'ingest_pw';
GRANT CONNECT ON DATABASE :"db" TO rag_reader, rag_ingest;

-- Dedicated schema owned by the admin: the app roles cannot create or drop tables.
CREATE SCHEMA rag;
GRANT USAGE ON SCHEMA rag TO rag_reader, rag_ingest;

-- Privileges on tables the admin will create later in this schema (step 5).
ALTER DEFAULT PRIVILEGES IN SCHEMA rag GRANT SELECT ON TABLES TO rag_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA rag GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rag_ingest;
ALTER DEFAULT PRIVILEGES IN SCHEMA rag GRANT USAGE, SELECT ON SEQUENCES TO rag_ingest;
SQL
