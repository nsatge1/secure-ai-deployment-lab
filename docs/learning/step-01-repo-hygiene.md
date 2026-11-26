# Step 1: Repository hygiene

## Difference between the pre-commit hook and `make scan-secrets`

The pre-commit hook is preventive: it stops a secret from being committed. `make scan-secrets` is a control: it scans the whole git history.

## What if a secret has already been committed?

No, deleting the secret from the repository is not enough. The secret is still in the history (`git log -p`). The secret is compromised, so we need to revoke it and rotate it. Then we can rewrite the history with `git filter-repo`.

## OWASP risks

Cutting off Internet access reduces the LLM02 risk (Sensitive Information Disclosure), because the model is not connected to the Internet. However, we need Internet access to download the model, which creates a supply chain risk (LLM03).
