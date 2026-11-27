# Step 5a: RAG schema, fictional documents and ingestion ADR

## What is RAG (Retrieval-Augmented Generation)?

It is an AI architecture that improves the accuracy and relevance of Large Language Models (LLMs) by:

- **Retrieving** relevant information from external knowledge bases or documents.
- **Augmenting** the user's prompt with this context.
- **Generating** a precise, fact-based response using the combined input.

It works in two phases: ingestion, then answering questions.

## Ingestion

### Chunking

We chunk the documents so that the embedding vectors are not blurry. An embedding summarizes a text in one vector: if the document covers several topics, the vector will be blurry and will not match any specific topic. Chunks also help us avoid disclosing too much information: we only share the necessary text.

### Embedding

The embedding model transforms the text into a vector. If we used one model to ingest the documents and a different model to transform the question, the vectors would no longer be in the same space, and we could not link the question to the documents.

### Injection risk

During ingestion, the injection risk is high: if an instruction is written in a document, we cannot filter it, because the instruction is in natural language, without any specific characters. Ingestion is the only moment when we can write to the database, so we are vulnerable: we need to verify the documents we ingest.

## Schema and data

### Why do we store the SHA-256 of each document?

We store the SHA-256 for versioning: we know which version of each document is in the database, but it does not protect the database or tell us whether the document is poisoned. It is used for detection and investigation, for example to understand a wrong answer. It is like step 3, with the hash of the model to know which model was downloaded.

### Why does the database check the hash?

The database checks the hash before inserting it because we do not trust the code. It is defense in depth: we are sure the hash has the right structure, to avoid breaking the database.

### Why use `ON DELETE CASCADE`?

If we modify a document, the ingestion deletes the document and ingests it again. Without `ON DELETE CASCADE`, if the old chunks are not deleted first, the database refuses to delete the document. This is a risk: the document is not updated in the database, so if the update fixed a vulnerability or wrong information, the chatbot keeps giving outdated answers.

### Where is the injection in the documents?

The injection is hidden in `remote-work-faq.md`, in an HTML comment (`<!-- … -->`). The ingestion chunks and embeds this section anyway, because for the ingestion code it is just raw text.
