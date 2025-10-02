#!/bin/sh

set -eu

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

export TERM=dumb
export NO_COLOR=1
export PATH="$PATH:$BASE_DIR/usr/bin"

# Terminate all child processes when this script is terminated
trap 'trap - INT TERM; kill -TERM -$$ 2>/dev/null; wait' INT TERM

lib/supervise.sh -- tailscale funnel 3205 &
lib/supervise.sh -- opt/adhoc-file-signer/bin/adhoc-sign-server --host 127.0.0.1 2>&1 &

case $(uname -o) in
MS/Windows)
    # 'wait' causes CPU spinning in BusyBox for Windows.
    # Using an endless loop instead as a workaround.
    while :; do
        # Do not sleep for too long to be able to receive signals soon enough
        sleep 1
    done
    ;;
*)
    # Wait for the background processes to finish.
    wait
    ;;
esac
