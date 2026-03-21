# BP-SEMGREP-STEP
A BP step to orchestrate Semgrep SAST (Static Application Security Testing) execution

## Setup
* Clone the code available at [BP-SEMGREP-STEP](https://github.com/OT-BUILDPIPER-MARKETPLACE/BP-SEMGREP-STEP)
* Build the docker image
```
git submodule init
git submodule update
docker build -t ot/semgrep:0.1 .
```

## Environment Variables
Some of the global environment variables that control the behaviour of scanning

| Variable | Default | Description |
|---|---|---|
| `SEMGREP_CONFIG` | `auto` | Semgrep ruleset to use. Can be `auto`, a registry pack like `p/owasp-top-ten`, `p/python`, or a path to a local config file |
| `OUTPUT_FILE` | `semgrep-report.json` | Output filename for the scan report (saved inside `reports/` directory) |
| `VALIDATION_FAILURE_ACTION` | `WARNING` | Set to `FAILURE` to fail the pipeline on findings, `WARNING` to continue |
| `SLEEP_DURATION` | `5s` | Wait duration before scan starts |
| `WORKSPACE` | *(required)* | Root workspace path |
| `CODEBASE_DIR` | *(required)* | Codebase directory relative to `WORKSPACE` |

## Testing

### Filesystem / Source Code Scan
Semgrep scans source code for security vulnerabilities, bugs, and policy violations.

If you want to use it independently you have to take care of below things:
* You have to set `WORKSPACE` env variable
* You have to set `CODEBASE_DIR` env variable
* Optionally set `SEMGREP_CONFIG` to control which rules are applied

```
# Scan with default auto config (WARNING mode - pipeline continues on findings)
docker run -it --rm \
  -v $PWD:/src \
  -e WORKSPACE=/ \
  -e CODEBASE_DIR=src \
  ot/semgrep:0.1
```

```
# Scan with OWASP Top 10 ruleset
docker run -it --rm \
  -v $PWD:/src \
  -e WORKSPACE=/ \
  -e CODEBASE_DIR=src \
  -e SEMGREP_CONFIG="p/owasp-top-ten" \
  ot/semgrep:0.1
```

```
# Strict scan - pipeline FAILS if findings are detected
docker run -it --rm \
  -v $PWD:/src \
  -e WORKSPACE=/ \
  -e CODEBASE_DIR=src \
  -e SEMGREP_CONFIG="auto" \
  -e VALIDATION_FAILURE_ACTION="FAILURE" \
  ot/semgrep:0.1
```

### Debugging
```
docker run -it --rm \
  -v $PWD:/src \
  -e WORKSPACE=/ \
  -e CODEBASE_DIR=src \
  --entrypoint bash \
  ot/semgrep:0.1
```

## Output
The scan report is saved as JSON at:
```
${WORKSPACE}/${CODEBASE_DIR}/reports/${OUTPUT_FILE}
```
Default path example: `/src/reports/semgrep-report.json`

## Reference
[Semgrep Docker Image](https://hub.docker.com/r/semgrep/semgrep)