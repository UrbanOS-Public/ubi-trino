#! /usr/bin/env sh

[[ "$1" == "quiet" ]] && QUIET=1 || QUIET=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOCAL_TRINO_VER="$(grep -E '^ARG TRINO_VERSION=' ${SCRIPT_DIR}/Dockerfile | cut -d '=' -f 2)"
UPSTREAM_TRINO_VER=$(${SCRIPT_DIR}/get_latest_repo_release_tag.sh)

RC=0
if [[ ${LOCAL_TRINO_VER} -lt ${UPSTREAM_TRINO_VER} ]]
then
    [[ ${QUIET} -eq 0 ]] && echo "A newer version of trino has been released (${UPSTREAM_TRINO_VER})"
    RC=1
else
    [[ ${QUIET} -eq 0 ]] && echo "Up to date with trinodb/trino"
fi

exit $RC
