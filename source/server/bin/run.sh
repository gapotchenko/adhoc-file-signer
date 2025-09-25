#!/bin/sh

set -eu

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

NAME=run.sh
VERSION=0.0.0

help() {
    echo "adhoc-file-signer/server  Version $VERSION
Copyright © Gapotchenko and Contributors

Runs the 'adhoc-file-signer' server.

Usage:
  $NAME [--host <server-host>] [--port <server-port>]

Options:
  --host  The server host to bind to. Defaults to 'localhost'.
  --port  The server port to listen at. Defaults to 3205."
}

# -----------------------------------------------------------------------------
# Options
# -----------------------------------------------------------------------------

OPT_HOST=localhost
OPT_PORT=3205

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
    --help)
        help
        exit
        ;;
    --host)
        OPT_HOST=$2
        shift 2
        ;;
    --port)
        OPT_PORT=$2
        shift 2
        ;;
    *)
        echo "$NAME: unknown option: $1" >&2
        exit 2
        ;;
    esac
done

# Validate options

opt_error_not_specified() {
    echo "$NAME: $1 not specified." >&2
    exit 2
}

if [ -z "$OPT_HOST" ]; then
    opt_error_not_specified 'server host'
fi

if [ -z "$OPT_PORT" ]; then
    opt_error_not_specified 'server port'
fi

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

log() {
    echo "$@"
}

error() {
    echo "$@" >&2
}

get_file_extension() {
    expr "x$1" : '.*\.\([^.]*\)$' | tr '[:upper:]' '[:lower:]' || true
}

# -----------------------------------------------------------------------------
# Core Functionality
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -fn -- "$0")")
BASE_DIR=$(dirname "$SCRIPT_DIR")
TMP_DIR=${TMPDIR-$(dirname "$(mktemp -u)")}

OS=$(uname -o)

validate_configuration() {
    log "Validating configuration..."

    if [ -z "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE-}" ]; then
        error "$NAME: GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE environment variable is not set."
        exit 2
    fi

    if [ -z "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD-}" ]; then
        case $(get_file_extension "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE-}") in
        pfx | p12)
            error "$NAME: GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE environment variable specifies a .pfx/.p12 certificate file, but GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD is not set."
            exit 2
            ;;
        esac
    fi

    if [ -z "${GP_ADHOC_FILE_SIGNER_FILE_DIGEST-}" ]; then
        error "$NAME: GP_ADHOC_FILE_SIGNER_FILE_DIGEST environment variable is not set."
        exit 2
    fi

    if [ -n "${GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER-}" ] && [ -z "${GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST-}" ]; then
        error "$NAME: GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER environment variable specifies a timestamp server URL, but GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST is not set."
        exit 2
    fi
}

initialize_host() {
    log "Host system: $OS"

    # Clean up any leftover session-scoped temporary files from previous runs.
    rm -rf "$TMP_DIR/adhoc-file-signer/run"
}

initialize_hsm() {
    log "HSM: initialization started..."

    # Prepare host OS
    case "$OS" in
    Cygwin | Msys | MS/Windows)
        # Windows

        # Ensuring that HSM-provided certificates are installed in the user's
        # certificate store.

        # Without these steps, the user certificate store may remain incomplete
        # and miss certificates provided by the HSM when running in a service
        # context.

        # Trigger population of the user certificate store.
        if command -v certutil >/dev/null 2>&1; then
            certutil -user -pulse ||
                log "HSM: 'certutil -user -pulse' did not complete successfully (continuing)."
        else
            log "HSM: certutil not found (skipping)."
        fi

        # Refresh certificates deployed by group policies.
        powershell -c 'gpupdate /target:user /force' ||
            log "HSM: gpupdate did not complete successfully (continuing)."
        ;;
    *) ;;
    esac

    # Initialize particular HSMs
    "$BASE_DIR/lib/hsm/safenet/initialize.sh"

    log "HSM: initialization done."
}

run_http() {
    log "Starting HTTP server..."
    exec "$BASE_DIR/srv/deno/run.sh" --host "$OPT_HOST" --port "$OPT_PORT" 2>&1
}

# -----------------------------------------------------------------------------

log "adhoc-file-signer/server  Version $VERSION"

validate_configuration
initialize_host

if [ -n "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE-}" ] &&
    [ -z "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD-}" ]; then
    # A certificate file without a password implies that it does not include a
    # private key. In this case, an HSM must be available to provide the key
    # material.

    # For the HSM to be available in a non-interactive user session, it should
    # be initialized first.
    log
    initialize_hsm
    log
fi

run_http
