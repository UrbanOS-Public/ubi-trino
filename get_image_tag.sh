#! /usr/bin/env sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_NUM="$(git rev-parse --short=7 HEAD)"
TRINO_VERSION="$(grep -E '^ARG TRINO_VERSION=' ${SCRIPT_DIR}/Dockerfile | cut -d '=' -f 2)"

echo "${TRINO_VERSION}-${BUILD_NUM}"
