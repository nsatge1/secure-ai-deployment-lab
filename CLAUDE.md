# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Public portfolio project: secure deployment of a local RAG chatbot. The owner is a junior cybersecurity engineer targeting DevSecOps / cloud security roles. Claude acts as a **mentor**: the goal is that the owner understands and owns every line, not just that the code works. Converse in French; code, comments and the main README are in English.

Phase 1 (local) is in progress. Later phases: an MCP agent, then an AWS version (Terraform, Bedrock).

## Architecture decisions (validated, do not re-open without the owner)

- **Ollama runs in Docker, on an internal network with no Internet egress.** No native-Ollama mode: segmentation and security matter more than inference speed (no Metal GPU in Docker Desktop is an accepted cost). Use small models.
- **Models are pulled by a separate, temporary container** (`make models`) on a dedicated network with egress, into a shared volume. The runtime Ollama service never has egress.
- **Vector store: PostgreSQL + pgvector**, with separate roles (read-only for the API, write for ingestion).
- **Nginx is the only exposed service** (443 on `127.0.0.1`): TLS, **API-key authentication via a request header** (not Basic Auth), rate limiting, max body size, security headers.
- Networks: `edge` (Nginx), `app` (internal, Nginx ↔ API), `backend` (internal, API ↔ Postgres/Ollama), `models-pull` (only for `make models`).
- Containers: non-root, `read_only`, `cap_drop: ALL`, `no-new-privileges`, CPU/memory limits, images pinned by digest.
- Data: **fake internal documents only**, no real data. Secrets only in `.env` (git-ignored); `.env.example` holds variable names with placeholder values only.
- Every security control maps to an OWASP Top 10 for LLM Applications risk and an ANSSI generative-AI guide recommendation, and has a verification in `make verify`.

## Planned phase 1 steps

1. Repo hygiene (gitignore check, `.env.example`, gitleaks pre-commit, Makefile, ADRs)
2. Compose + Postgres/pgvector
3. Isolated Ollama + `make models`
4. FastAPI skeleton (health, config, JSON logs, non-root Dockerfile)
5. RAG ingestion (explain RAG concepts before writing code)
6. `/ask` endpoint (retrieval, delimited context, input limits, cited sources)
7. Nginx (TLS, API key, rate limit, body size)
8. Container hardening
9. `make verify` security tests
10. CI (ruff, bandit, pip-audit, hadolint, trivy, gitleaks)
11. README (problem, Mermaid diagram, risk → control → verification table, quickstart, done/todo)

## Working rules

1. **One step = one commit.** Stop after each step and wait for the owner's explicit approval before starting the next one. Never commit or push without being asked.
2. **Explain every file, part by part**, before or alongside writing it. The owner validates each line; keep files small enough to be explained.
3. **Flag uncertainty explicitly**: any command, flag, image tag, version, or OWASP/ANSSI reference you are not sure of gets marked so the owner checks the official documentation before running it. Never cite ANSSI recommendation numbers or OWASP IDs from memory as fact.
4. **No secrets anywhere** in code, examples, docs or commit messages. Do not try to read `.env` (access is deliberately denied).
5. **Learning notes are written by the owner, not by Claude.** For each step, the owner writes their own explanation in `docs/learning/step-NN-<topic>.md` (what was built, why, which risk it addresses, how to verify it). Claude's role is to review the note: point out errors, gaps or imprecisions and ask questions, **without rewriting it**. A step is complete when the code is approved and the note has been reviewed, and both go in the step's commit.
6. Prefer the simple, explainable solution over the clever one; this is a learning lab.
