# Entry point for every task in the lab. Run `make` or `make help` to list targets.

.DEFAULT_GOAL := help
.PHONY: help env hooks scan-secrets

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

env: ## Create .env from .env.example (never overwrites) and restrict its permissions
	@if [ -f .env ]; then \
		echo ".env already exists, left untouched"; \
	else \
		cp .env.example .env && echo ".env created: replace every CHANGE_ME value"; \
	fi
	@chmod 600 .env

hooks: ## Install the git pre-commit hooks (requires pre-commit)
	pre-commit install

scan-secrets: ## Scan the whole git history for secrets (requires gitleaks)
	gitleaks git --redact --verbose .
