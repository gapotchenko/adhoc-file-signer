#!/bin/sh

# Your feedback and contributions are welcome:
# https://github.com/gapotchenko/adhoc-file-signer

set -eu

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Enusre that the tools we depend on are in PATH.
PATH="$PATH:$BASE_DIR/usr/bin"

# TODO

call_signtool() {
    file=$1
    signtool sign -f "$GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE" -csp "$GP_ADHOC_FILE_SIGNER_CSP" -kc "$GP_ADHOC_FILE_SIGNER_KEY_CONTAINER" -fd "$GP_ADHOC_FILE_SIGNER_FILE_DIGEST" -tr "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER" -td "$GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST" "$file"
}

call_signtool "$1"
