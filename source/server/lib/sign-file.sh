#!/bin/sh

set -eu

NAME=sign-file.sh
VERSION=0.0.0

help() {
    echo "$NAME  Version $VERSION
Copyright © Gapotchenko and Contributors

Signs the specified file using configuration parameters provided via
environment variables.

Usage: $NAME <file>

Configuration (environment variables):
  - GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE:
    The path to a certificate file (.pfx, .p12, or .cer in DER format)

Your feedback and contributions are welcome:
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

FILE=

add_file() {
    if [ -z "$FILE" ]; then
        FILE=$1
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
        add_file "$1"
        shift
        ;;
    esac
done

# Complete positional arguments
while [ $# -gt 0 ]; do
    add_file "$1"
    shift
done

# Validate options
if [ -z "$FILE" ]; then
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
# Auxilary Functions for NuGet
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

    # Signing key parameters
    if [ -n "${GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE-}" ]; then
        set -- "$@" -f "$GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE"
    fi
    if [ -n "${GP_ADHOC_FILE_SIGNER_CSP-}" ]; then
        set -- "$@" -csp "$GP_ADHOC_FILE_SIGNER_CSP"
    fi
    if [ -n "${GP_ADHOC_FILE_SIGNER_KEY_CONTAINER-}" ]; then
        set -- "$@" -kc "$GP_ADHOC_FILE_SIGNER_KEY_CONTAINER"
    fi
    if [ -n "${GP_ADHOC_FILE_SIGNER_FILE_DIGEST-}" ]; then
        set -- "$@" -fd "$GP_ADHOC_FILE_SIGNER_FILE_DIGEST"
    fi

    # Timestamping parameters
    if [ -n "${GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER-}" ]; then
        set -- "$@" -tr "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER"
    fi
    if [ -n "${GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST-}" ]; then
        set -- "$@" -td "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST"
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
    file=$FILE
    fileext=$(expr "x$file" : '.*\.\([^.]*\)$' | tr '[:upper:]' '[:lower:]' || true)
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
