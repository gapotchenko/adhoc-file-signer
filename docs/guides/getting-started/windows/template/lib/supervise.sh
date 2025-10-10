#!/bin/sh

set -eu

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

NAME=supervise.sh
VERSION=1.0.0

help() {
    echo "$NAME v$VERSION
Copyright © Gapotchenko and Contributors

Ensures that the specified command stays running.

Usage:
  $NAME [-d <delay>] [-m <max-retries>] -- command [args...]

Options:
  -d --delay        Wait time in seconds before restarting the command.
                    The default delay is 2 seconds.
  -m --max-retries  Maximum number of restart attempts before giving up.
                    Use 0 for unlimited retries (default).

Project page: https://github.com/gapotchenko/supervise.sh"
}

# -----------------------------------------------------------------------------
# Options
# -----------------------------------------------------------------------------

# Default configuration
OPT_DELAY=2
OPT_MAX_RETRIES=0

# Parse options
while [ $# -gt 0 ]; do
    case $1 in
    --help)
        help
        exit
        ;;
    -d | --delay)
        OPT_DELAY=$2
        shift 2
        ;;
    -m | --max-retries)
        OPT_MAX_RETRIES=$2
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "$NAME: unknown option: $1" >&2
        exit 1
        ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "$NAME: missing program arguments
Try '$NAME --help' for more information." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Auxilary Functions
# -----------------------------------------------------------------------------

log() {
    printf '%s: %s: %s\n' "$NAME" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

# -----------------------------------------------------------------------------
# Core Functionality
# -----------------------------------------------------------------------------

RETRY_COUNT=0

while :; do
    STATUS=0
    "$@" || STATUS=$?
    log "Process exited with status $STATUS."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$OPT_MAX_RETRIES" -ne 0 ] && [ "$RETRY_COUNT" -ge "$OPT_MAX_RETRIES" ]; then
        log "Reached max retries ($OPT_MAX_RETRIES). Exiting."
        exit 1
    fi
    log "Restarting in $OPT_DELAY seconds (attempt $RETRY_COUNT)..."
    sleep "$OPT_DELAY"
done
