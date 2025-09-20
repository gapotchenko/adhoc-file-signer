#!/bin/sh

# Your feedback and contributions are welcome:
# https://github.com/gapotchenko/adhoc-file-signer

set -eu

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Enusre that the tools we depend on are in PATH.
PATH="$PATH:$BASE_DIR/usr/bin"

echo TODO

# signtool

echo "File being processed: $1"
echo "Addendum" >>"$1"
