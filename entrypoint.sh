#!/bin/sh
set -e

script_name=$(basename "$0")

log() {
    # Depending on params, log an info,warn, or error message
    # $1 = message
    # $2 = log level
    logtime=$(date +'%Y-%m-%dT%H:%M:%S%z')
    # Set log_level based on $2
    case $2 in
        "warn")
            log_level="WARN"
            ;;
        "error")
            log_level="ERROR"
            ;;
        *)
            log_level="INFO"
            ;;
    esac
    echo "${logtime} ${script_name} $log_level $1"
}

log "Starting $script_name"

# Set the ATOM_LOCALHOSTID
if [ "${BOOMI_ENVIRONMENT_CLASS}" = "LOCAL" ]; then
    log "environment class set to LOCAL, using hosts file" "warn"
    NODE_IP=$(awk 'END{print $1}' /etc/hosts)
else
    log "Using AWS metadata to get the task ARN and extract the task ID"
    NODE_IP="TASK_$(curl -s http://169.254.170.2/v2/metadata | jq -r .TaskARN | grep -oE '[^/]+$')"
fi
export ATOM_LOCALHOSTID="${NODE_IP}"

log "ATOM_LOCALHOSTID = ${ATOM_LOCALHOSTID}"

# Sleep between 2-61 seconds to allow the environment to stabilize
# This also helps avoid a race condition on container.properties file in EFS when multiple containers start
random_sleep=$((RANDOM % 60 + 2))
log "Sleeping for ${random_sleep} seconds to allow the environment to stabilize" "warn"
sleep "${random_sleep}"

exec "$@"
