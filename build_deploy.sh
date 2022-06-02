#!/bin/bash

set -exv

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

IMAGE_REPO="quay.io"
ORG="cloudservices"
APP="ubi-trino"
IMAGE="${IMAGE_REPO}/${ORG}/${APP}"
IMAGE_TAG=$(${SCRIPT_DIR}/get_image_tag.sh)

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

# if [[ -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
#     echo "RH_REGISTRY_USER and RH_REGISTRY_TOKEN  must be set"
#     exit 1
# fi

changed=$(git diff --name-only ^HEAD~1|| egrep -v deploy/clowdapp.yaml) # do not build if only the `deploy/clowdapp.yaml` file has changed
if [ -n "$changed" ]; then
    # docker is used on the RHEL7 nodes
    # DOCKER_CONF="$PWD/.docker"
    # mkdir -p "$DOCKER_CONF"
    # docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
    # # docker --config="$DOCKER_CONF" login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
    # docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG}" ${SCRIPT_DIR}
    # docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG}"
    # docker --config="$DOCKER_CONF" logout

    # podman is used on the RHEL8 nodes
    podman login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
    # podman login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
    # podman build -t "${IMAGE}:${IMAGE_TAG}" ${SCRIPT_DIR}
    podman build --arch=amd64 -t "${IMAGE}:${IMAGE_TAG}.amd64" -f ${SCRIPT_DIR}
    podman build --arch=arm64 -t "${IMAGE}:${IMAGE_TAG}.arm64" -f ${SCRIPT_DIR}

    podman manifest create "${IMAGE}:${IMAGE_TAG}"
    podman manifest add "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:${IMAGE_TAG}.amd64"
    podman manifest add "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:${IMAGE_TAG}.arm64"

    podman push "${IMAGE}:${IMAGE_TAG}"
    podman tag "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:latest"
    podman push "${IMAGE}:latest"
fi
