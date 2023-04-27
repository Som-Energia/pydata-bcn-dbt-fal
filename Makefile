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

sh: ## run a shell in the container
	@docker compose run --rm -it --entrypoint sh app

sh.target-builder: ## run a shell in the container
	@docker compose run --rm -it --entrypoint sh builder

# ---------------------------------------------------------------------------- #
#             Testing, auto formatting, type checks, & Lint checks             #
# ---------------------------------------------------------------------------- #

pytest: ## run pytest inside the container
	docker compose run --rm app pytest -p no:warnings -v /app/dags

format: ## run black formatter inside the container
	docker compose run --rm app python -m black -S --line-length 79 .

isort: ## run isort formatter for python imports inside the container
	docker compose run --rm app isort .

type: ## run mypy type checker inside the container
	docker compose run --rm app mypy --ignore-missing-imports /app/

lint: ## run flake8 linter inside the container
	docker compose run --rm ruff check /app/

ci: isort format type lint pytest ## run CI checks inside the container

# ---------------------------------------------------------------------------- #
#                                 novu demo app                                #
# ---------------------------------------------------------------------------- #

novu.demo-app.install: ## install the demo app provided by novu
	@cd notification-center-demo && npm run setup:onboarding -- kemCTwJofzaN 982454b92921646f6ce5bcec45c2d4cf http://localhost:3000 http://localhost:3002

novu.demo-app.launch: ## install the demo app provided by novu
	@cd notification-center-demo && npm run devq