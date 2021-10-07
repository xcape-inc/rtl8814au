#!/bin/bash
set -e
trap 'catch $? $LINENO' ERR
catch() {
  echo "Error $1 occurred on $2" >&2
}
set -euo pipefail

SCRIPT_PATH=$0

if [[ "$OSTYPE" == "darwin"* ]]; then
  # MacOS equivalent of readlink -f

  cd $(dirname "${SCRIPT_PATH}")
  SCRIPT_BASE_NAME=$(basename "${SCRIPT_PATH}")

  # Iterate down a (possible) chain of symlinks
  CUR_TARGET=${SCRIPT_BASE_NAME}
  while [ -L "${SCRIPT_BASE_NAME}" ]
  do
      CUR_TARGET=$(readlink "${CUR_TARGET}")
      cd $(dirname "${CUR_TARGET}")
      CUR_TARGET=$(basename "${CUR_TARGET}")
  done

  # Compute the canonicalized name by finding the physical path 
  # for the directory we're in and appending the target file.
  SCRIPT_DIR=$(pwd -P)
  REAL_SCRIPT_PATH="${SCRIPT_DIR}/${CUR_TARGET}"
else
  REAL_SCRIPT_PATH=$(readlink -f "${SCRIPT_PATH}")
  SCRIPT_DIR=$(dirname "${REAL_SCRIPT_PATH}")
fi

cd "${SCRIPT_DIR}"

# build the .env file
if [[ 'true' != "${SKIP_ENV_FILE:-}" ]]; then
  echo "REGISTRY_URI=ghcr.io/
DOCKER_NAMESPACE=DOCKER_NAMESPACE/
SRC_DIR=${SCRIPT_DIR}
IMAGE_VERSION=${IMAGE_VERSION:-}" > docker_builder/.env

  echo "generated .env file >>>"
  cat docker_builder/.env && echo "<<<"
fi

cd docker_builder
COMPOSE_FILE_PATH=docker-compose.yml

# try to pull the associated docker images from the remote repo; will build otherwise
if [[ 'true' == "${FORCE_PULL:-}" ]]; then
  docker-compose -f "${COMPOSE_FILE_PATH}" ${COMPOSE_DEBUG_FLAGS:-} pull
elif [[ 'true' != "${SKIP_PULL:-}" ]]; then
  echo "** trying to pull"
  docker-compose -f "${COMPOSE_FILE_PATH}" ${COMPOSE_DEBUG_FLAGS:-} pull || true
  echo "** done trying to pull"
fi

echo "docker-compose rendered from vars >>>"
docker-compose -f "${COMPOSE_FILE_PATH}" ${COMPOSE_DEBUG_FLAGS:-} config && echo "<<<"

echo "Taking down any existing containers and volumes for this project"
docker-compose -f "${COMPOSE_FILE_PATH}" ${COMPOSE_DEBUG_FLAGS:-} down -v || true

# docker-compose run will build any needed images
exec docker-compose -f "${COMPOSE_FILE_PATH}" ${COMPOSE_DEBUG_FLAGS:-} run --rm builder
