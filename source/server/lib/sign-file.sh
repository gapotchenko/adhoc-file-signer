#!/bin/sh

set -eu

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

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure that the tools we depend on are in PATH.
PATH="$PATH:$BASE_DIR/usr/bin"

# -----------------------------------------------------------------------------
# Auxilary Functions
# -----------------------------------------------------------------------------

get_file_extension() {
    expr "x$1" : '.*\.\([^.]*\)$' | tr '[:upper:]' '[:lower:]' || true
}

# -------------------------------------
# Windows
# -------------------------------------

translate_windows_path() {
    if [ -n "${WSL_DISTRO_NAME-}" ]; then
        wslpath "$1"
    else
        printf '%s' "$1" | tr "\\\\" '/'
    fi
}

# -------------------------------------
# NuGet
# -------------------------------------

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
        echo "NuGet tool is not found." >&2
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
# Core Functionality
# -----------------------------------------------------------------------------

signtool_sign() {
    file=$1

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
}

nuget_sign() {
    file=$1
    detect_nuget

    echo "TODO NuGet" >&2
    exit 1
}

# -----------------------------------------------------------------------------

run_on_windows() {
    file=$OPT_FILE
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
