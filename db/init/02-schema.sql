-- Runs once, after 01-roles.sh, as the admin role (official postgres image behaviour).
-- The tables belong to the admin: the app roles only get the privileges
-- declared with ALTER DEFAULT PRIVILEGES in 01-roles.sh.

-- One row per ingested file.
CREATE TABLE rag.documents (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Path relative to the documents folder, e.g. "leave-policy.md". One row per file.
    source      text        NOT NULL UNIQUE,
    title       text        NOT NULL,
    -- SHA-256 of the exact file that was ingested (traceability, LLM04).
    sha256      char(64)    NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
    ingested_at timestamptz NOT NULL DEFAULT now()
);

-- One row per chunk: the text sent to the LLM and its vector used for the search.
CREATE TABLE rag.chunks (
    id          bigint  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Deleting a document deletes its chunks: re-ingesting a changed file leaves no orphans.
    document_id bigint  NOT NULL REFERENCES rag.documents (id) ON DELETE CASCADE,
    -- Order of the chunk in its document (0, 1, 2...).
    position    integer NOT NULL CHECK (position >= 0),
    content     text    NOT NULL,
    -- Must equal the output size of the embedding model: 768 for nomic-embed-text (verified).
    embedding   vector(768) NOT NULL,
    UNIQUE (document_id, position)
);

-- No vector index (HNSW): with a few dozen chunks, an exact scan is instant. See ADR 0002.
