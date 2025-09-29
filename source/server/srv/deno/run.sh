#!/bin/sh

set -eu

# -----------------------------------------------------------------------------

OPT_HOST=localhost
OPT_PORT=3205
OPT_MODE=run

# Parse options
while [ $# -gt 0 ]; do
    case $1 in
    --help)
        echo "Usage: run.sh [develop] [--host <host>] [--port <port>]"
        exit
        ;;
    develop)
        OPT_MODE=develop
        shift
        ;;
    --host)
        OPT_HOST="$2"
        shift 2
        ;;
    --port)
        OPT_PORT="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 2
        ;;
    esac
done

# -----------------------------------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -fn -- "$0")")
cd "$SCRIPT_DIR"

export DENO_FUTURE=1

deno_config() {
    deno "$@"
}

deno_sandbox() {
    deno_config serve --host "$OPT_HOST" --port "$OPT_PORT" --allow-net '--allow-run=/bin/sh,gnu-tk' '--allow-env=GP_ADHOC_FILE_SIGNER_*' "$@"
}

deno_run() {
    DENO_NO_PROMPT=1 deno_sandbox "$@"
}

# -----------------------------------------------------------------------------

if [ "$OPT_MODE" = "run" ]; then
    # Run the app
    deno_run serve.ts
elif [ "$OPT_MODE" = "develop" ]; then
    # Development run
    deno_sandbox --watch serve.ts
else
    exit 2
fi
