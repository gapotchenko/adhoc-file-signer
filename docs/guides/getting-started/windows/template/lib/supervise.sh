#!/bin/sh

# supervise.sh - a tiny supervisor script.
# Ensures that the specified command is always running.

# Default configuration
DELAY=2       # seconds
MAX_RETRIES=0 # 0 means unlimited

usage() {
    echo "Usage: supervise.sh [-d delay] [-m max-retries] -- command [args...]" >&2
    exit 1
}

# Parse options
while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --delay)
        DELAY="$2"
        shift 2
        ;;
    -m | --max-retries)
        MAX_RETRIES="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        usage
        ;;
    esac
done

[ "$#" -gt 0 ] || usage

log() {
    printf '%s: supervise.sh: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

RETRY_COUNT=0

while :; do
    "$@"
    STATUS=$?
    log "Process exited with status $STATUS."
    if [ "$STATUS" -eq 130 ]; then
        log "Cancelled. Exiting."
        exit 130
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$MAX_RETRIES" -ne 0 ] && [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        log "Reached max retries ($MAX_RETRIES). Exiting."
        exit 1
    fi
    log "Restarting in $DELAY seconds (attempt $RETRY_COUNT)..."
    sleep "$DELAY"
done
