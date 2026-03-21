FROM semgrep/semgrep:1.154.0

WORKDIR /home/buildpiper

# Install required system packages and create buildpiper user
RUN apk --no-cache add \
    bash jq gettext libintl curl && \
    addgroup -g 65522 buildpiper && \
    adduser -D -h /home/buildpiper -u 65522 -G buildpiper buildpiper && \
    mkdir -p /home/buildpiper && \
    chown -R buildpiper:buildpiper /home/buildpiper

# Create necessary directories and assign permissions
RUN mkdir -p \
    /src/reports \
    /bp/data \
    /bp/execution_dir \
    /opt/buildpiper/shell-functions \
    /bp/workspace && \
    chown -R buildpiper:buildpiper /src /bp /opt

# Copy files with correct ownership
COPY --chown=buildpiper:buildpiper build.sh /home/buildpiper/build.sh
COPY --chown=buildpiper:buildpiper semGrepScanner.sh /home/buildpiper/semGrepScanner.sh
COPY --chown=buildpiper:buildpiper BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# Also copy to WORKDIR so relative entrypoint works
COPY build.sh .
COPY semGrepScanner.sh .

# Make scripts executable
RUN chmod +x /home/buildpiper/build.sh && \
    chmod +x /home/buildpiper/semGrepScanner.sh

# Task and execution configuration
ENV ACTIVITY_SUB_TASK_CODE="BP-SEMGREP-TASK" \
    SLEEP_DURATION="5s" \
    VALIDATION_FAILURE_ACTION="WARNING" \
    DEBUG="false"
    
# Semgrep scan configuration
ENV SEMGREP_CONFIG="auto" \
    REPORT_TYPE="json" \
    OUTPUT_CSV="semgrep_scan_report.csv" \
    OUTPUT_FILE="semgrep_scan_report.json"

# Application and organization info
ENV APPLICATION_NAME="" \
    ORGANIZATION="" \
    SOURCE_KEY="" \
    REPORT_FILE_PATH="null" \
    MI_SERVER_ADDRESS=""

# Final permissions
RUN chown -R buildpiper:buildpiper /bp/workspace && \
    mkdir -p /home/buildpiper/reports && \
    chown -R buildpiper:buildpiper /home/buildpiper

# Switch to non-root user
USER buildpiper

ENTRYPOINT ["./build.sh"]