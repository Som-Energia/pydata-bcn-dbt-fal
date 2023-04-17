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
	docker compose run --rm app flake8 /app/dags

ci: isort format type lint pytest ## run CI checks inside the container

# ---------------------------------------------------------------------------- #
#                               debugging entries                              #
# ---------------------------------------------------------------------------- #

debug.build: ## build image using docker build
	@docker build -t ${SOMENERGIA_REGISTRY_IMAGE}:${SOMENERGIA_DOCKER_TAG} -f Dockerfile.poetry --no-cache . --progress=plain

debug.build.target-builder: ## pass the --target=builder flag to docker build
	@docker build -t ${SOMENERGIA_REGISTRY_IMAGE}:${SOMENERGIA_DOCKER_TAG}-builder --target=builder -f Dockerfile.poetry --no-cache . --progress=plain
