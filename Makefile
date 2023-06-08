.DEFAULT_GOAL := help
.PHONY: help

include .env
export

# taken from https://container-solutions.com/tagging-docker-images-the-right-way/

help: ## Print this help
	@grep -E '^[0-9a-zA-Z_\-\.]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## build docker images with docker compose
	@docker compose build --progress=plain

build-from-scratch: ## build docker images and ignore existing caches
	@docker compose build --progress=plain --no-cache

run.bash: ## run a bash shell in the container
	@docker compose run --rm -it --entrypoint bash dev_env

exec.bash: ## run a bash shell in the container
	@docker compose exec -it dev_env bash

sh.target-builder: ## run a shell in the container
	@docker compose run --rm -it --entrypoint sh builder

# ---------------------------------------------------------------------------- #
#             Testing, auto formatting, type checks, & Lint checks             #
# ---------------------------------------------------------------------------- #

pytest: ## run pytest inside the container
	docker compose run --rm dev_env pytest -p no:warnings -v /app/dags

format: ## run black formatter inside the container
	docker compose run --rm dev_env python -m black -S --line-length 79 .

isort: ## run isort formatter for python imports inside the container
	docker compose run --rm dev_env isort .

type: ## run mypy type checker inside the container
	docker compose run --rm dev_env mypy --ignore-missing-imports /app/

lint: ## run flake8 linter inside the container
	docker compose run --rm ruff check /app/

ci: isort format type lint pytest ## run CI checks inside the container


# ---------------------------------------------------------------------------- #
#                                 dbt examples                                 #
# ---------------------------------------------------------------------------- #

demo.forecast: ## launch demo forecast with REE data
	@dbt run --target dev_with_fal --selector ree_forecast --project-dir pydata_bcn_dbt/