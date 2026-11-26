# Step 2: PostgreSQL with pgvector and least-privilege roles

## Why use `environment:` in Compose instead of `env_file:`?

If we use `env_file:`, the container can access every key, including the API key. We only pass the variables the container needs. This is the principle of least privilege.

## What if the API is compromised?

An attacker could only read the data. They could not modify, delete or create data.
If `rag_ingest` is compromised, the attacker could only modify the data in the tables. They could not create, modify or delete tables.
The admin role can do everything. That is why the admin role should never be assigned to an API that is accessible from the Internet.

## OWASP risks

Separating the roles reduces the LLM08 risk: Vector and Embedding Weaknesses. The API role can only read the data, not modify it. This is important because if the API is compromised, the attacker cannot modify the data to poison it (LLM04).

## Why do we use the `reader_pw` variable?

We use the `reader_pw` variable because pasting the password into the SQL text could break the string and allow SQL injection, for example if the password contains a `'`. With the variable, psql knows how to handle this character when it is in the password.
