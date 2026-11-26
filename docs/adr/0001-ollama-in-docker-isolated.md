# ADR 0001: Run Ollama in Docker on an isolated network

- **Status:** Accepted
- **Date:** 2026-11-25

## Context

The lab serves a local LLM for a RAG chatbot on a Mac M2. Two options exist:

1. **Native Ollama on macOS.** Uses the M2 GPU through Metal, so inference is fast.
   But it runs as the developer's user, with Internet access and access to the
   home directory. Containers reach it through `host.docker.internal`, which
   breaks network segmentation.
2. **Ollama in a Docker container.** Docker Desktop runs containers in a Linux VM
   without Metal GPU access, so inference runs on CPU only and is much slower.
   In exchange, the container can be attached to an internal network with no
   egress, run without root, and have its resources capped.

The purpose of this lab is to demonstrate segmentation and least privilege,
not inference performance.

## Decision

Run Ollama **only** in Docker, attached to an internal network (`backend`)
with no route to the Internet. No native mode is provided.

Models are downloaded by a separate, short-lived container (`make models`)
on a dedicated network that has egress. It writes into a volume that the
runtime Ollama container then mounts. The runtime container never has egress.

Small models are used to keep CPU inference acceptable.

## Consequences

- **Positive:** the "model has no Internet access" control is real and testable
  (`make verify`). This limits data exfiltration and model-initiated outbound
  calls. The setup is reproducible on any machine with Docker.
- **Negative:** slow responses; limited to small models. Accepted.
- **To watch:** the model-pull step is the only moment with egress. It is a
  supply-chain entry point (OWASP LLM03), so pulled models must be pinned and
  traceable.

## References (to verify in the official documents)

- OWASP Top 10 for LLM Applications: LLM03 Supply Chain, LLM10 Unbounded Consumption.
- ANSSI, *Recommandations de sécurité pour un système d'IA générative*: recommendations
  on isolating the components of the AI system (exact numbers to be cited from the PDF).
