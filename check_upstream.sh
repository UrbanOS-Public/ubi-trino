#!/usr/bin/env bash

[[ "$1" == "quiet" ]] && QUIET=1 || QUIET=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOCAL_PRESTO_VER=$(${SCRIPT_DIR}/get_trino_version.sh)
UPSTREAM_PRESTO_VER=$(${SCRIPT_DIR}/get_latest_repo_release_tag.sh)

RC=0
if [[ ${LOCAL_PRESTO_VER} -lt ${UPSTREAM_PRESTO_VER} ]]
then
    [[ ${QUIET} -eq 0 ]] && echo "A newer version of trino has been released (${UPSTREAM_PRESTO_VER})"
    RC=1
else
    [[ ${QUIET} -eq 0 ]] && echo "Up to date with trinodb/trino"
fi

exit $RC
