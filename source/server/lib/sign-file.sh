#!/usr/bin/env bash

set -eu

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

NAME=sign-file.sh
VERSION=0.0.0

help() {
    echo "$NAME  Version $VERSION
Copyright © Gapotchenko and Contributors

Signs the specified file using configuration parameters provided through
command-line options or environment variables.

Usage: $NAME [option...] <file>

Certificate selection options:
  --cert-file  Path to a certificate file (.pfx, .p12, or .cer in DER format).
               Defaults to the value of GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE
               environment variable if not specified.
  --cert-pass  Password to use when opening a .pfx or .p12 certificate file.
               Defaults to \$GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD.
  --csp        CSP containing the private key container.
               Defaults to \$GP_ADHOC_FILE_SIGNER_CSP.
  --kc         Key container name of the private key.
               Defaults to \$GP_ADHOC_FILE_SIGNER_KEY_CONTAINER.

Signing parameter options:
  --file-digest  File digest algorithm to use for creating file signatures.
                 Defaults to \$GP_ADHOC_FILE_SIGNER_FILE_DIGEST.

Timestamping parameter options:
  --time-server  RFC 3161 timestamp server URL. If omitted, the signed file
                 will not be timestamped.
                 Defaults to \$GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER.
  --time-digest  Digest algorithm to use for timestamps.
                 Defaults to \$GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST.

Feedback and contributions are welcome:
https://github.com/gapotchenko/adhoc-file-signer"
}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

get_file_extension() {
    expr "x$1" : '.*\.\([^.]*\)$' | tr '[:upper:]' '[:lower:]' || true
}

# -----------------------------------------------------------------------------
# Options
# -----------------------------------------------------------------------------

if [ $# -eq 0 ]; then
    echo "$NAME: missing program arguments
Try '$NAME --help' for more information." >&2
    exit 2
fi

OPT_FILE=
OPT_CERTIFICATE_FILE=${GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE-}
OPT_CERTIFICATE_PASSWORD=${GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD-}
OPT_CSP=${GP_ADHOC_FILE_SIGNER_CSP-}
OPT_KEY_CONTAINER=${GP_ADHOC_FILE_SIGNER_KEY_CONTAINER-}
OPT_FILE_DIGEST=${GP_ADHOC_FILE_SIGNER_FILE_DIGEST-}
OPT_TIMESTAMP_SERVER=${GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER-}
OPT_TIMESTAMP_DIGEST=${GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST-}

opt_add_file() {
    if [ -z "$OPT_FILE" ]; then
        OPT_FILE=$1
    else
        echo "$NAME: only one file can be specified" >&2
        exit 2
    fi
}

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
    --help)
        help
        exit
        ;;
    --cert-file)
        OPT_CERTIFICATE_FILE=$2
        shift 2
        ;;
    --cert-pass)
        OPT_CERTIFICATE_PASSWORD=$2
        shift 2
        ;;
    --csp)
        OPT_CSP=$2
        shift 2
        ;;
    --kc)
        OPT_KEY_CONTAINER=$2
        shift 2
        ;;
    --file-digest)
        OPT_FILE_DIGEST=$2
        shift 2
        ;;
    --time-server)
        OPT_TIMESTAMP_SERVER=$2
        shift 2
        ;;
    --time-digest)
        OPT_TIMESTAMP_DIGEST=$2
        shift 2
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo "$NAME: unknown option: $1" >&2
        exit 2
        ;;
    *)
        # Positional arguments
        opt_add_file "$1"
        shift
        ;;
    esac
done

# Validate options

if [ -z "$OPT_CERTIFICATE_PASSWORD" ]; then
    case $(get_file_extension "$OPT_CERTIFICATE_FILE") in
    pfx | p12)
        echo "$NAME: a .pfx/.p12 certificate file is specified, but the certificate password is not provided." >&2
        exit 2
        ;;
    esac
fi

if [ -z "$OPT_FILE_DIGEST" ]; then
    echo "$NAME: file digest algorithm is not specified." >&2
    exit 2
fi

if [ -n "$OPT_TIMESTAMP_SERVER" ] && [ -z "$OPT_TIMESTAMP_DIGEST" ]; then
    echo "$NAME: timestamp server URL is specified, but timestamp digest algorithm is not provided." >&2
    exit 2
fi

# Complete positional arguments
while [ $# -gt 0 ]; do
    opt_add_file "$1"
    shift
done

# Validate positional options
if [ -z "$OPT_FILE" ]; then
    echo "$NAME: file is not specified." >&2
    exit 2
fi

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname -- "$(readlink -fn -- "$0" || echo "$0")")" && pwd)
BASE_DIR=$(dirname "$SCRIPT_DIR")
TMP_DIR=${TMPDIR-$(dirname "$(mktemp -u)")}

# Ensure that the tools we depend on are in PATH.
PATH="$PATH:$BASE_DIR/usr/bin"

# -----------------------------------------------------------------------------
# Auxilary Functions
# -----------------------------------------------------------------------------

log() {
    echo "$@" >&2
}

error() {
    echo "$@" >&2
}

on_exit() {
    if [ "$1" -ne 0 ]; then
        error "$NAME: failed with status $1."
    fi
    # Cleanup
    [ -n "${tmpfile-}" ] && rm -f "$tmpfile" || true
    # Preserve the status
    exit "$1"
}

trap 'on_exit "$?"' EXIT

# -----------------------------------------------------------------------------
# Windows
# -----------------------------------------------------------------------------

translate_windows_path() {
    if [ -n "${WSL_DISTRO_NAME-}" ]; then
        wslpath "$1"
    else
        printf '%s' "$1" | tr "\\\\" '/'
    fi
}

# -----------------------------------------------------------------------------
# NuGet
# -----------------------------------------------------------------------------

detect_nuget() {
    # shellcheck disable=SC2034

    if command -v nuget >/dev/null 2>&1; then
        # NuGet as a standalone command
        NUGET_PATH=nuget
        NUGET_ARG_PROLOG=
        # Argument names
        NUGET_ARG_CERTIFICATE_FINGERPRINT=-CertificateFingerprint
        NUGET_ARG_CERTIFICATE_PASSWORD=-CertificatePassword
        NUGET_ARG_CERTIFICATE_PATH=-CertificatePath
        NUGET_ARG_CERTIFICATE_STORE_LOCATION=-CertificateStoreLocation
        NUGET_ARG_CERTIFICATE_STORE_NAME=-CertificateStoreName
        NUGET_ARG_HASH_ALGORITHM=-HashAlgorithm
        NUGET_ARG_NON_INTERACTIVE=-NonInteractive
        NUGET_ARG_OVERWRITE=-Overwrite
        NUGET_ARG_TIMESTAMPER=-Timestamper
        NUGET_ARG_TIMESTAMP_HASH_ALGORITHM=-TimestampHashAlgorithm
    elif command -v dotnet >/dev/null 2>&1; then
        # NuGet as part of dotnet
        NUGET_PATH=dotnet
        NUGET_ARG_PROLOG=nuget
        # Argument names
        NUGET_ARG_CERTIFICATE_FINGERPRINT=--certificate-fingerprint
        NUGET_ARG_CERTIFICATE_PASSWORD=--certificate-password
        NUGET_ARG_CERTIFICATE_PATH=--certificate-path
        NUGET_ARG_CERTIFICATE_STORE_LOCATION=--certificate-store-location
        NUGET_ARG_CERTIFICATE_STORE_NAME=--certificate-store-name
        NUGET_ARG_HASH_ALGORITHM=--hash-algorithm
        NUGET_ARG_NON_INTERACTIVE=
        NUGET_ARG_OVERWRITE=--overwrite
        NUGET_ARG_TIMESTAMPER=--timestamper
        NUGET_ARG_TIMESTAMP_HASH_ALGORITHM=--timestamp-hash-algorithm
    else
        error "NuGet tool is not found."
        exit 1
    fi
}

call_nuget() {
    if [ -n "$NUGET_ARG_PROLOG" ]; then
        "$NUGET_PATH" "$NUGET_ARG_PROLOG" "$@"
    else
        "$NUGET_PATH" "$@"
    fi
}

# -----------------------------------------------------------------------------
# HSM
# -----------------------------------------------------------------------------

hsm_is_used() {
    if [ -n "$OPT_CERTIFICATE_FILE" ] && [ -z "$OPT_CERTIFICATE_PASSWORD" ]; then
        return 0
    else
        return 1
    fi
}

HSM_LOGON_MARK_FILE="$TMP_DIR/adhoc-file-signer/run/hsm-logon-mark"

hsm_mark_logon() {
    mkdir -p "$(dirname "$HSM_LOGON_MARK_FILE")"
    echo >"$HSM_LOGON_MARK_FILE"
}

hsm_logon_marked() {
    if [ -f "$HSM_LOGON_MARK_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Core Functionality
# -----------------------------------------------------------------------------

signtool_sign() {
    local file=$1

    set -- # empty argv

    # Certificate parameters
    if [ -n "$OPT_CERTIFICATE_FILE" ]; then
        set -- "$@" -f "$OPT_CERTIFICATE_FILE"
    fi
    if [ -n "$OPT_CERTIFICATE_PASSWORD" ]; then
        set -- "$@" -p "$OPT_CERTIFICATE_PASSWORD"
    fi
    if [ -n "$OPT_CSP" ]; then
        set -- "$@" -csp "$OPT_CSP"
    fi
    if [ -n "$OPT_KEY_CONTAINER" ]; then
        set -- "$@" -kc "$OPT_KEY_CONTAINER"
    fi

    # Signing parameters
    if [ -n "$OPT_FILE_DIGEST" ]; then
        set -- "$@" -fd "$OPT_FILE_DIGEST"
    fi

    # Timestamping parameters
    if [ -n "$OPT_TIMESTAMP_SERVER" ]; then
        set -- "$@" -tr "$OPT_TIMESTAMP_SERVER"
    fi
    if [ -n "$OPT_TIMESTAMP_DIGEST" ]; then
        set -- "$@" -td "$OPT_TIMESTAMP_DIGEST"
    fi

    # Call signtool
    signtool sign "$@" "$file"

    if hsm_is_used; then
        hsm_mark_logon
    fi
}

hsm_logon() {
    if hsm_is_used; then
        # Perform HSM logon only once per session
        if ! hsm_logon_marked; then
            log "HSM: attempting logon"

            # Trigger HSM logon by signing a temporary specimen file with signtool
            tmpfile=$(mktemp -t "$NAME.specimen.XXXXXX.cab")
            cp "$BASE_DIR/share/sign-file.sh/specimen.cab" "$tmpfile"
            # Signtool does the actual HSM logon as a useful side effect of signing
            OPT_TIMESTAMP_SERVER='' OPT_TIMESTAMP_DIGEST='' signtool_sign "$tmpfile" >/dev/null
            # Discard the signed file
            rm "$tmpfile"
            unset tmpfile

            log "HSM: logon has been completed successfully"

            # Mark that HSM logon has been completed for this session
            hsm_mark_logon
        fi
    fi
}

nuget_sign() {
    local file=$1

    detect_nuget

    local certthumb
    if [ "$(get_file_extension "$OPT_CERTIFICATE_FILE")" = "cer" ]; then
        # Public key certificate in DER format.
        certthumb=$(sha256sum "$(translate_windows_path "$OPT_CERTIFICATE_FILE")" | awk '{print $1}')
    else
        # Private key certificate in PKCS#12 container format.
        certthumb=
    fi

    hsm_logon

    set -- # empty argv

    # Certificate parameters
    if [ -n "$certthumb" ]; then
        set -- "$@" "$NUGET_ARG_CERTIFICATE_FINGERPRINT" "$certthumb"
    else
        if [ -n "$OPT_CERTIFICATE_FILE" ]; then
            set -- "$@" "$NUGET_ARG_CERTIFICATE_PATH" "$OPT_CERTIFICATE_FILE"
        fi
        if [ -n "$OPT_CERTIFICATE_PASSWORD" ]; then
            set -- "$@" "$NUGET_ARG_CERTIFICATE_PASSWORD" "$OPT_CERTIFICATE_PASSWORD"
        fi
    fi

    # Signing parameters
    if [ -n "$OPT_FILE_DIGEST" ]; then
        set -- "$@" "$NUGET_ARG_HASH_ALGORITHM" "$OPT_FILE_DIGEST"
    fi

    # Timestamping parameters
    if [ -n "$OPT_TIMESTAMP_SERVER" ]; then
        set -- "$@" "$NUGET_ARG_TIMESTAMPER" "$OPT_TIMESTAMP_SERVER"
    fi
    if [ -n "$OPT_TIMESTAMP_DIGEST" ]; then
        set -- "$@" "$NUGET_ARG_TIMESTAMP_HASH_ALGORITHM" "$OPT_TIMESTAMP_DIGEST"
    fi

    # Other
    if [ -n "$NUGET_ARG_NON_INTERACTIVE" ]; then
        set -- "$@" -f "$NUGET_ARG_NON_INTERACTIVE"
    fi

    # Call NuGet
    call_nuget sign "$file" "$@" "$NUGET_ARG_OVERWRITE"
}

# -----------------------------------------------------------------------------

run_on_windows() {
    local file=$OPT_FILE

    local fileext
    fileext=$(get_file_extension "$file")

    case "$fileext" in
    nupkg)
        nuget_sign "$file"
        ;;
    *)
        signtool_sign "$file"
        ;;
    esac
}

run_on_other_os() {
    echo "$NAME: needs implementation for $OS operating system.
Edit $NAME file according to your needs. Consider to contribute your
changes back to https://github.com/gapotchenko/adhoc-file-signer project." >&2
    exit 1
}

OS=$(uname -o)
case "$OS" in
Cygwin | Msys | MS/Windows)
    run_on_windows
    ;;
*)
    run_on_other_os
    ;;
esac
