#!/bin/sh

# Your feedback and contributions are welcome:
# https://github.com/gapotchenko/adhoc-file-signer

set -eu

NAME=sign-file.sh

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure that the tools we depend on are in PATH.
PATH="$PATH:$BASE_DIR/usr/bin"

# TODO

call_signtool() {
    file=$1
    signtool sign -f "$GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE" -csp "$GP_ADHOC_FILE_SIGNER_CSP" -kc "$GP_ADHOC_FILE_SIGNER_KEY_CONTAINER" -fd "$GP_ADHOC_FILE_SIGNER_FILE_DIGEST" -tr "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER" -td "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST" "$file"
}

run_on_windows() {
    call_signtool "$1"
}

os=$(uname -o)
case "$os" in
Cygwin | Msys | MS/Windows)
    run_on_windows "$@"
    ;;
*)
    echo "$NAME: needs implementation for $os operating system.
Edit $NAME file according to your needs. Consider to contribute your
changes back to https://github.com/gapotchenko/adhoc-file-signer project." >&2
    exit 1
    ;;
esac
