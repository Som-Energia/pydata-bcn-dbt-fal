# ---------------------------------------------------------------------------- #
#                      example usage for docker and poetry                     #
# ---------------------------------------------------------------------------- #

# References:
# - https://inboard.bws.bio/docker#docker-and-poetry
# - https://github.com/br3ndonland/inboard/blob/0.45.0/Dockerfile
# - https://github.com/python-poetry/poetry/issues/1178
# - https://github.com/python-poetry/poetry/issues/1178#issuecomment-1238475183

# ---------------------------------------------------------------------------- #
#                                  build stage                                 #
# ---------------------------------------------------------------------------- #

# Global ARG, available to all stages (if renewed)
ARG WORKDIR="/app"

# tag used in all images
ARG PYTHON_VERSION=3.10.9

FROM python:${PYTHON_VERSION} AS builder

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
RUN python -m pip install --no-cache-dir --upgrade pip pipx==${PIPX_VERSION}
RUN pipx ensurepath && pipx --version

# Install Poetry using pipx
RUN pipx install --force poetry==${POETRY_VERSION}

# Copy everything to the container, we filter out what we don't need using .dockerignore
WORKDIR ${WORKDIR}
COPY . .

# Install dependencies
RUN poetry install --with dev

# ---------------------------------------------------------------------------- #
#                                   app stage                                  #
# ---------------------------------------------------------------------------- #

# We don't want to use alpine because it doesn't have the `musl` C library
# https://stackoverflow.com/a/67695490/5819113
FROM python:${PYTHON_VERSION}-slim as app

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


# ---------------------------------------------------------------------------- #
#                                user management                               #
# ---------------------------------------------------------------------------- #

# For more on users and groups
# see https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes
# see https://stackoverflow.com/a/55757473/5819113
# see https://stackoverflow.com/questions/56844746/how-to-set-uid-and-gid-in-docker-compose
# see https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid

ARG UID
ARG GID
ARG UNAME

ENV UID=${UID:-1000}
ENV GID=${GID:-1000}
ENV UNAME=${UNAME:-somenergia}

RUN groupadd \
	--gid $GID \
	"$UNAME" && \
	useradd \
	--no-log-init \
	--home-dir "${WORKDIR}" \
	--uid $UID \
	--gid $GID \
	--no-create-home \
	"$UNAME"

USER ${UID}

# ---------------------------------------------------------------------------- #
#                             App-specific settings                            #
# ---------------------------------------------------------------------------- #

ENTRYPOINT [ "python" ]
CMD [ "--version" ]