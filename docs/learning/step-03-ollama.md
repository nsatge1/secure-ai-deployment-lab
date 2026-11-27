# Step 3: isolated non-root Ollama and separate model pull

## Why two services (`ollama` and `models-pull`)?

`models-pull` needs Internet access to download the models, but we want the model to run only on the backend network, without Internet access, because Internet access is an additional risk. So we download the models with `models-pull`, on an isolated network that has Internet access, and the models run only on the backend network, without Internet access.

## Why is `models-pull` not on the backend network?

Because `models-pull` needs to be connected to the Internet, and for security we want our backend to be isolated from the Internet. That is why `models-pull` is isolated on its own network. `models-pull` is not on the backend network so that, if it is compromised by a malicious model, the attacker cannot reach the backend network.

## Why do we use `:ro` in `compose.yaml`, and which OWASP risk does it address?

`ro` means read-only. This means the server cannot modify or replace the models. This protects against the OWASP risk LLM04: Data and Model Poisoning, because if the server could modify the models, an attacker could replace them with a poisoned model.

## Why do we use the model ID?

We use the ID because a model with a tag like `llama3.2:3b` could be replaced by a poisoned model (LLM03: Supply Chain). To protect against LLM03, we need to use the ID to be sure about the model version.

The IDs I have validated:

| Model | ID |
|---|---|
| `nomic-embed-text:latest` | `0a109f422b47` |
| `llama3.2:3b` | `a80c4f17acd5` |

## What are an embedding and RAG?

Ingestion means cutting the documents into chunks and converting them into embeddings. An embedding is a vector (a list of numbers) that represents the meaning of the text. Two similar texts have similar embeddings. RAG (Retrieval-Augmented Generation) uses these embeddings to search the database for similar embeddings, and sends only the necessary chunks with the question to the LLM.
