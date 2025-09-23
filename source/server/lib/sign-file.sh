#!/bin/sh

set -eu

NAME=sign-file.sh

help() {
    echo "$NAME
Copyright © Gapotchenko and Contributors

Signs the specified file using configuration provided via environment
variables.

Usage: $NAME <file>

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
# Core Functionality
# -----------------------------------------------------------------------------

call_signtool() {
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
    signtool sign "$@" "$FILE"
}

call_nuget_sign() {
    echo "TODO NuGet" >&2
    exit 1
}

run_on_windows() {
    file=$FILE
    fileext=$(expr "x$file" : '.*\.\([^.]*\)$' | tr '[:upper:]' '[:lower:]' || true)
    case "$fileext" in
    nupkg)
        call_nuget_sign "$file"
        ;;
    *)
        call_signtool "$file"
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
