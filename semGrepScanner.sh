#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/mi-functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/str-functions.sh
source /opt/buildpiper/shell-functions/file-functions.sh
source /opt/buildpiper/shell-functions/aws-functions.sh

if [ "$DEBUG" = true ]; then
  set -x
fi

cd ${WORKSPACE}/${CODEBASE_DIR}

if [ -d "reports" ]; then
    true
else
    mkdir reports
fi

STATUS=0

logInfoMessage "============================"
logInfoMessage "Start Semgrep SAST Scanning"
logInfoMessage "============================"

SCAN_PATH="${WORKSPACE}/${CODEBASE_DIR}"
JSON_REPORT="reports/${OUTPUT_FILE}"

logInfoMessage "I'll scan codebase at ${SCAN_PATH} using config: ${SEMGREP_CONFIG}"
sleep $SLEEP_DURATION
logInfoMessage "Executing command"

if [[ "${REPORT_TYPE}" == "json" || "${REPORT_TYPE}" == "both" ]]; then

    logInfoMessage "Generating JSON report: ${JSON_REPORT}"
    logInfoMessage "semgrep scan --config ${SEMGREP_CONFIG} --json --output ${JSON_REPORT} ${SCAN_PATH}"

    semgrep scan \
        --config ${SEMGREP_CONFIG} \
        --json \
        --output ${JSON_REPORT} \
        ${SCAN_PATH}

    STATUS=$?
    logInfoMessage "Semgrep JSON report generated at ${JSON_REPORT}"

else
    logErrorMessage "Invalid REPORT_TYPE provided. Supported: json, both"
    STATUS=1
fi


if [[ "${REPORT_TYPE}" == "json" || "${REPORT_TYPE}" == "both" ]]; then

    if [ -s "${JSON_REPORT}" ]; then
        ERROR=$(jq '([.results[]? | select(.extra.severity=="ERROR")] | length) // 0' "${JSON_REPORT}" 2>/dev/null || echo 0)
        WARNING=$(jq '([.results[]? | select(.extra.severity=="WARNING")] | length) // 0' "${JSON_REPORT}" 2>/dev/null || echo 0)
        INFO=$(jq '([.results[]? | select(.extra.severity=="INFO")] | length) // 0' "${JSON_REPORT}" 2>/dev/null || echo 0)
    else
        ERROR=0; WARNING=0; INFO=0
    fi

    logInfoMessage "Scan Summary -> ERROR: ${ERROR} | WARNING: ${WARNING} | INFO: ${INFO}"

    HORIZONTAL_CSV="reports/${OUTPUT_CSV}"
    echo "RuleID,File,Line,Severity,Message,CWE" > "${HORIZONTAL_CSV}"

    if [ -s "${JSON_REPORT}" ]; then
        jq -r '
          .results[]?
          | [
              (.check_id // "N/A"),
              (.path // "N/A"),
              (.start.line // "N/A" | tostring),
              (.extra.severity // "N/A"),
              (.extra.message // "N/A" | gsub("\n"; " ") | gsub(","; ";")),
              ((.extra.metadata.cwe // ["N/A"]) | if type == "array" then first else . end | gsub(","; ";"))
            ]
          | @csv
        ' "${JSON_REPORT}" >> "${HORIZONTAL_CSV}" 2>/dev/null || true

        logInfoMessage "Generated Semgrep CSV report at ${HORIZONTAL_CSV}"
    else
        logWarningMessage "No JSON report available; CSV created empty."
    fi

fi


if [ -n "${GLOBAL_TASK_ID:-}" ]; then
    mkdir -p "/bp/execution_dir/${GLOBAL_TASK_ID}/"
    cp -rf reports/* "/bp/execution_dir/${GLOBAL_TASK_ID}/"
    logInfoMessage "Copied reports to /bp/execution_dir/${GLOBAL_TASK_ID}/"
else
    logWarningMessage "GLOBAL_TASK_ID not set; skipping copy to execution_dir"
fi


if [ $STATUS -eq 0 ]
then
  logInfoMessage "Congratulations Semgrep scan succeeded!!!"
  generateOutput ${ACTIVITY_SUB_TASK_CODE} true "Congratulations Semgrep scan succeeded!!!"
elif [ $VALIDATION_FAILURE_ACTION == "FAILURE" ]
  then
    logErrorMessage "Please check Semgrep scan failed!!!"
    generateOutput ${ACTIVITY_SUB_TASK_CODE} false "Please check Semgrep scan failed!!!"
    exit 1
  else
    logWarningMessage "Please check Semgrep scan failed!!!"
    generateOutput ${ACTIVITY_SUB_TASK_CODE} true "Please check Semgrep scan failed!!!"
fi