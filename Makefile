# Entry point for every task in the lab. Run `make` or `make help` to list targets.

.DEFAULT_GOAL := help
.PHONY: help env hooks scan-secrets check-env models up down ps logs db-shell clean

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

check-env: ## Refuse to start if .env is missing or still has placeholders
	@test -f .env || { echo "Missing .env: run 'make env' first"; exit 1; }
	@if grep -q CHANGE_ME .env; then \
		echo "Replace every CHANGE_ME value in .env before starting"; exit 1; \
	fi

models: check-env ## Download the models (the only step with Internet access)
	docker compose --profile tools run --rm --build models-pull

up: check-env ## Build if needed, start the stack and wait until services are healthy
	docker compose up -d --build --wait

down: ## Stop the stack (data volumes are kept)
	docker compose down

ps: ## Show services and their health
	docker compose ps

logs: ## Follow the logs of all services
	docker compose logs -f

db-shell: ## Open a psql shell as the admin, inside the db container
	docker compose exec db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

clean: ## Stop the stack AND delete its volumes (all data is lost)
	docker compose down -v
