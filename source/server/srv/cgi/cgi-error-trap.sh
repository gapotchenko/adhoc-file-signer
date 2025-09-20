#!/usr/bin/env bash

# cgi-error-trap.sh
#
# Traps CGI command errors and communicates them to the client when possible.
#
# Usage: cgi-error-trap.sh -- <command> [args...]

# We cannot use `set -e` because we need to handle child non-zero exits ourselves.
set -u

# Drop a leading -- if present
if [ "${1-}" = "--" ]; then
    shift
fi

if [ $# -eq 0 ]; then
    echo "$SERVER_PROTOCOL 500 Internal Server Error"
    echo 'Content-Type: text/plain; charset=utf-8'
    echo 'X-CGI-ExitCode: 2'
    echo
    echo 'No command specified.'
    exit 2
fi

countfile=$(mktemp -t cgi-error-trap.count.XXXXXX) || exit 1
errfile=$(mktemp -t cgi-error-trap.err.XXXXXX) || exit 1

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
