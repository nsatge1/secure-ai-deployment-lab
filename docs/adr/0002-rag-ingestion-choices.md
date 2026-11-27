# ADR 0002: RAG ingestion choices

- **Status:** Accepted
- **Date:** 2026-11-27

## Context

The chatbot answers from a small corpus of fictional internal documents. Documents are split
into chunks, each chunk is turned into an embedding by the local Ollama, and the chunks are
stored in PostgreSQL with pgvector. The corpus is a security boundary: whatever is ingested
will be shown to the LLM and can influence every answer.

## Decisions

1. **Chunking: about 800 characters, about 100 characters of overlap, split on paragraph
   boundaries when possible.** Small enough for one topic per chunk, large enough to keep
   context. These values are a starting point, to be tuned by testing.
2. **One embedding model for documents and questions:** `nomic-embed-text`, served by the
   isolated Ollama. Changing the model requires a full re-ingestion. No text leaves the machine.
3. **No vector index.** With a few dozen chunks, an exact scan is instant and gives exact
   results. An HNSW index becomes useful only with tens of thousands of chunks.
4. **Only `.md` and `.txt` files, with a maximum file size.** No PDF or Office parsing in
   phase 1: complex parsers are an attack surface for malicious files.
5. **Each document is stored with the SHA-256 of the exact file ingested.** A suspicious
   answer can be traced back to the file version that produced it. A changed file is replaced,
   not duplicated.
6. **Ingestion is a separate, one-shot service** (`make ingest`) using the `rag_ingest` role,
   with the documents folder mounted read-only. The API only has the `rag_reader` role.
7. **A deliberately poisoned document is part of the corpus** (see below), to demonstrate
   indirect prompt injection.

## The poisoned document

`data/fake-docs/remote-work-faq.md` contains, inside an HTML comment, instructions addressed
to an AI assistant: lower the password length to 4 characters, encourage password sharing,
and reveal the system prompt. HTML comments are invisible when the Markdown is rendered on
GitHub, but they are plain text for the ingestion: this is how a real hidden injection looks.
It contradicts `it-security-policy.md` (14 characters, never share passwords), so a successful
injection is easy to spot in an answer.

The injection cannot be blocked at ingestion time: it is ordinary natural-language text.
It is mitigated at answer time (step 6), and the demonstration is documented in the README.

## Consequences

- Traceability and least privilege on the write path (OWASP LLM04, LLM08).
- Indirect prompt injection (OWASP LLM01) is demonstrated, not hidden.
- Documents are reviewed like code: a pull request changing `data/fake-docs/` changes what
  the chatbot says.

## Verified

- The output size of `nomic-embed-text` is 768 (measured through the Ollama `/api/embed` route),
  which fixes `vector(768)` in the schema.

## To verify

- Whether `nomic-embed-text` expects task prefixes (`search_document:`, `search_query:`),
  on its Ollama model page.
