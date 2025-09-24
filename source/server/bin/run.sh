#!/bin/sh

set -eu

# -----------------------------------------------------------------------------
# Options
# -----------------------------------------------------------------------------

# TODO

# -----------------------------------------------------------------------------
# Core Functionality
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -fn -- "$0")")
BASE_DIR=$(dirname "$SCRIPT_DIR")
TMP_DIR=${TMPDIR-$(dirname "$(mktemp -u)")}

OS=$(uname -o)

log() {
    echo "$@"
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

log "Starting HTTP server..."
exec "$BASE_DIR/srv/deno/run.sh" "$@" 2>&1
