#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/mi-functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/str-functions.sh
source /opt/buildpiper/shell-functions/file-functions.sh
source /opt/buildpiper/shell-functions/aws-functions.sh

git config --global --add safe.directory "$(pwd)"

CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"

logInfoMessage "Starting Semgrep Scan"
logInfoMessage "Workspace: ${WORKSPACE}/${CODEBASE_DIR}"

/home/buildpiper/semGrepScanner.sh