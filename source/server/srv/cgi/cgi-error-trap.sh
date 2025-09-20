#!/usr/bin/env bash

set -u

NAME=cgi-error-trap.sh

help() {
    echo "$NAME
Copyright © Gapotchenko and Contributors

Captures errors from CGI commands and, when possible, reports them back to the
client in a user-friendly format.

Usage: $NAME -- <command> [args...]"
}

# -----------------------------------------------------------------------------

error=

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
    *)
        error="$NAME: unknown option: $1"
        ;;
    esac
done

if [ $# -eq 0 ]; then
    error="$NAME: missing program arguments"
fi

if [ -n "$error" ]; then
    echo "${SERVER_PROTOCOL-HTTP/1.1} 500 Internal Server Error"
    echo 'Content-Type: text/plain; charset=utf-8'
    echo 'X-CGI-ExitCode: 2'
    echo
    echo "$error"
    echo "Try '$NAME --help' for more information."
    exit 2
fi

# -----------------------------------------------------------------------------

countfile=$(mktemp -t "$NAME.count.XXXXXX") || exit 1
errfile=$(mktemp -t "$NAME.err.XXXXXX") || exit 1

# shellcheck disable=SC2329
on_exit() {
    rm -f "$countfile" "$errfile"
}

trap on_exit EXIT

# Run the command:
# - stdout: streamed to both client and wc -c
# - stderr: captured and mirrored to stderr
"$@" 2> >(tee "$errfile" >&2) |
    tee >(wc -c >"$countfile")

cmd_status=${PIPESTATUS[0]}

# Read byte count
bytes_out=0
if [ -s "$countfile" ]; then
    read -r bytes_out <"$countfile"
    # some wc implementations prefix spaces; strip them
    bytes_out="${bytes_out#"${bytes_out%%[![:space:]]*}"}"
fi

# Synthesize CGI 500 if failed and no stdout
if [ "$cmd_status" -ne 0 ] && [ "$bytes_out" -eq 0 ]; then
    echo "$SERVER_PROTOCOL 500 Internal Server Error"
    echo 'Content-Type: text/plain; charset=utf-8'
    echo "X-CGI-ExitCode: $cmd_status"
    echo
    cat "$errfile"
fi

exit "$cmd_status"
