#!/bin/bash

set -exv

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

IMAGE_REPO="quay.io"
ORG="urbanos"
APP="ubi-trino"
IMAGE="${IMAGE_REPO}/${ORG}/${APP}"
IMAGE_TAG_DEFAULT=$(${SCRIPT_DIR}/get_image_tag.sh)
IMAGE_TAG_AMD=$(${SCRIPT_DIR}/get_image_tag.sh)-amd64

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

# if [[ -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
#     echo "RH_REGISTRY_USER and RH_REGISTRY_TOKEN  must be set"
#     exit 1
# fi

# Create tmp dir to store data in during job run (do NOT store in $WORKSPACE)
export TMP_JOB_DIR=$(mktemp -d -p "$HOME" -t "jenkins-${JOB_NAME}-${BUILD_NUMBER}-XXXXXX")
echo "job tmp dir location: $TMP_JOB_DIR"

function job_cleanup() {
    echo "cleaning up job tmp dir: $TMP_JOB_DIR"
    rm -fr $TMP_JOB_DIR
}

trap job_cleanup EXIT ERR SIGINT SIGTERM

#changed=$(git diff --name-only ^HEAD~1|| egrep -v deploy/clowdapp.yaml) # do not build if only the `deploy/clowdapp.yaml` file has changed
#if [ -n "$changed" ]; then
    # docker is used on the RHEL7 nodes
    # DOCKER_CONF="$PWD/.docker"
    # mkdir -p "$DOCKER_CONF"
    # docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
    # # docker --config="$DOCKER_CONF" login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
    # docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG}" ${SCRIPT_DIR}
    # docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG}"
    # docker --config="$DOCKER_CONF" logout

    # podman is used on the RHEL8 nodes
#    podman login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
#    # podman login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
#    podman build -t "${IMAGE}:${IMAGE_TAG}" ${SCRIPT_DIR}
#    podman push "${IMAGE}:${IMAGE_TAG}"
#    podman tag "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:latest"
#    podman push "${IMAGE}:latest"

  DOCKER_CONF="$TMP_JOB_DIR/.docker"
  mkdir -p "$DOCKER_CONF"
  docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
  docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG_DEFAULT}" ${SCRIPT_DIR} --progress=plain --no-cache
  docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG_DEFAULT}"

  docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG_AMD}" ${SCRIPT_DIR} --progress=plain --no-cache --platform linux/amd64
  docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG_AMD}"

  docker --config="$DOCKER_CONF" tag "${IMAGE}:${IMAGE_TAG_AMD}" "${IMAGE}:latest"
  docker --config="$DOCKER_CONF" push "${IMAGE}:latest"

  docker --config="$DOCKER_CONF" logout

#fi
