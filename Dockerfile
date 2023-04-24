# ---------------------------------------------------------------------------- #
#                      example usage for docker and poetry                     #
# ---------------------------------------------------------------------------- #

# References:
# - https://inboard.bws.bio/docker#docker-and-poetry
# - https://github.com/br3ndonland/inboard/blob/0.45.0/Dockerfile
# - https://github.com/python-poetry/poetry/issues/1178
# - https://github.com/python-poetry/poetry/issues/1178#issuecomment-1238475183


# ---------------------------------------------------------------------------- #
#                            global build arguments                            #
# ---------------------------------------------------------------------------- #

# Global ARG, available to all stages (if renewed)
ARG WORKDIR="/app"

# global username
ARG USERNAME=pydata
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# tag used in all images
ARG PYTHON_VERSION=3.10.9

# ---------------------------------------------------------------------------- #
#                                  pre stage                                 #
# ---------------------------------------------------------------------------- #

FROM python:${PYTHON_VERSION} AS pre

# Renew (https://stackoverflow.com/a/53682110):
ARG WORKDIR

# Poetry version
ARG POETRY_VERSION=1.4.0

# Pipx version
ARG PIPX_VERSION=1.2.0

# prepare the $PATH
ENV PATH=/opt/pipx/bin:${WORKDIR}/.venv/bin:$PATH \
	PIPX_BIN_DIR=/opt/pipx/bin \
	PIPX_HOME=/opt/pipx/home \
	PIPX_VERSION=$PIPX_VERSION \
	POETRY_VERSION=$POETRY_VERSION \
	PYTHONPATH=${WORKDIR} \
	# Don't buffer `stdout`
	PYTHONUNBUFFERED=1 \
	# Don't create `.pyc` files:
	PYTHONDONTWRITEBYTECODE=1 \
	# make poetry create a .venv folder in the project
	POETRY_VIRTUALENVS_IN_PROJECT=true

# Install Pipx using pip

# trunk-ignore(hadolint/DL3013)
RUN python -m pip install --no-cache-dir --upgrade pip pipx==${PIPX_VERSION}

RUN pipx ensurepath && pipx --version

# Install Poetry using pipx
RUN pipx install --force poetry==${POETRY_VERSION}

# Copy everything to the container, we filter out what we don't need using .dockerignore
WORKDIR ${WORKDIR}
COPY . .

# ---------------------------------------------------------------------------- #
#                                 builder stage                                #
# ---------------------------------------------------------------------------- #

FROM pre AS builder
#
# Install dependencies
RUN poetry install

# ---------------------------------------------------------------------------- #
#                                 only docs stage                               #
# ---------------------------------------------------------------------------- #

FROM pre AS dbt-docs-builder

# Install dependencies
RUN poetry install --only dbt-docs

# pull dbt dependencies
RUN dbt deps --project-dir pydata_bcn_dbt/

# build static pages
RUN dbt docs generate --project-dir pydata_bcn_dbt/


# ---------------------------------------------------------------------------- #
#                                   dev stage                                  #
# ---------------------------------------------------------------------------- #

FROM pre AS develop

ARG USERNAME
ARG USER_UID
ARG USER_GID

# ----------------------- add development dependencies ----------------------- #

# trunk-ignore(hadolint/DL3008)
# trunk-ignore(hadolint/DL3015)
RUN apt-get update \
	&& apt-get install vim netcat iputils-ping -y

# Create the user
# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
# trunk-ignore(hadolint/DL3008)
# trunk-ignore(hadolint/DL3015)
RUN groupadd --gid $USER_GID $USERNAME \
	&& useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
	#
	# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
	&& apt-get update \
	&& apt-get install -y sudo \
	&& echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
	&& chmod 0440 /etc/sudoers.d/$USERNAME

# ------------------------------ user management ----------------------------- #
# ownership of the workdir to non-root user
RUN chown -R "${USER_UID}:${USER_GID}" "${WORKDIR}"

# install dev dependencies
RUN poetry install --with dev

USER ${USERNAME}

# ---------------------------------------------------------------------------- #
#                                   app stage                                  #
# ---------------------------------------------------------------------------- #

# We don't want to use alpine because porting from debian is challenging
# https://stackoverflow.com/a/67695490/5819113
FROM python:${PYTHON_VERSION}-slim AS app

# refresh ARG
ARG WORKDIR

# refresh PATH
ENV PATH=/opt/pipx/bin:${WORKDIR}/.venv/bin:$PATH \
	POETRY_VERSION=$POETRY_VERSION \
	PYTHONPATH=${WORKDIR} \
	# Don't buffer `stdout`
	PYTHONUNBUFFERED=1 \
	# Don't create `.pyc` files:
	PYTHONDONTWRITEBYTECODE=1

WORKDIR ${WORKDIR}

COPY --from=builder ${WORKDIR} .

# ------------------------------ user management ----------------------------- #

# For more on users and groups
# see https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes
# see https://stackoverflow.com/a/55757473/5819113
# see https://stackoverflow.com/questions/56844746/how-to-set-uid-and-gid-in-docker-compose
# see https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid

# refresh global arguments
ARG USERNAME
ARG USER_UID
ARG USER_GID

RUN groupadd \
	--gid $USER_GID \
	"$USERNAME" && \
	useradd \
	--no-log-init \
	--home-dir "${WORKDIR}" \
	--uid $USER_UID \
	--gid $USER_GID \
	--no-create-home \
	"$USERNAME"

USER ${USERNAME}

# ------------------------------- app specific ------------------------------- #

ENTRYPOINT [ "python" ]
CMD [ "--version" ]


# ---------------------------------------------------------------------------- #
#                                  docs serve                                  #
# ---------------------------------------------------------------------------- #

# serve site
FROM nginx:stable-alpine AS dbt-docs

# refresh ARG
ARG WORKDIR

# here copy any nginx related files you might need for your deployment, for example nginx.conf
# ADD ...
COPY --from=dbt-docs-builder \
	${WORKDIR}/pydata_bcn_dbt/target/index.html \
	${WORKDIR}/pydata_bcn_dbt/target/manifest.json \
	${WORKDIR}/pydata_bcn_dbt/target/catalog.json \
	${WORKDIR}/pydata_bcn_dbt/target/run_results.json \
	/usr/share/nginx/html/

EXPOSE 80
