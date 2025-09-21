#!/bin/sh

set -eu

help() {
    echo 'cgi-file-transform.sh
Copyright © Gapotchenko and Contributors

Receives a file, transforms it with the specified command, then sends the
transformed file back. Supports over-the-wire compression and data integrity
verification.

Usage: cgi-file-transform.sh -- <command> [args...]'
}

# -----------------------------------------------------------------------------

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
        echo "Unknown option: $1" >&2
        exit 2
        ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "$NAME: missing program arguments
Try '$NAME --help' for more information."
    exit 2
fi

# -----------------------------------------------------------------------------

#SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
#LOG_FILE="$SCRIPT_DIR/log.txt"

on_exit() {
    [ -n "${tmpfile-}" ] && rm -f "$tmpfile"
    [ -n "${resfile-}" ] && rm -f "$resfile"
}

trap 'on_exit' EXIT

# -----------------------------------------------------------------------------
# Receive and store a file
# -----------------------------------------------------------------------------

fileext="${HTTP_X_FILE_EXTENSION-}"

# Validate the file extension.
# Allow only letters, digits, underscores, or dashes.
# ^...$ anchors the regex to the entire string.
if ! expr "x$fileext" : '^x[A-Za-z0-9_-]\+$' >/dev/null; then
    # Assign an explicit ".noext" extension to prevent downstream transforms
    # from accidentally interpreting a random part of the file name as an
    # extension.
    fileext=noext
fi

tmpfile=$(mktemp -t "cgi-file-transform.XXXXXX.$fileext")

if [ "${HTTP_CONTENT_ENCODING-}" = "gzip" ]; then
    # gzip compression
    gzip -d >"$tmpfile" 2>/dev/null
elif [ "${HTTP_CONTENT_ENCODING-}" = "zstd" ]; then
    # zstd compression
    zstd -d -f -o "$tmpfile" 2>/dev/null
else
    # No compression
    cat >"$tmpfile"
fi

# -----------------------------------------------------------------------------
# Verify integrity of the received file
# -----------------------------------------------------------------------------

EXPECTED_CONTENT_DIGEST="${HTTP_CONTENT_DIGEST-}"

hex_to_bin() {
    if command -v xxd >/dev/null 2>&1; then
        xxd -r -p
    else
        awk '{ for (i=1; i<=length($0); i+=2) printf "%c", strtonum("0x" substr($0,i,2)) }'
    fi
}

sha256_b64() {
    sha256sum "$1" | awk '{print $1}' | hex_to_bin | base64
}

sha256_digest() {
    echo "sha-256=$(sha256_b64 "$1")"
}

digest_verification_failed() {
    echo "$SERVER_PROTOCOL 400 Bad Request"
    echo "Content-Type: text/plain;charset=UTF-8"
    echo "Want-Content-Digest: sha-256=1"
    echo
    echo "Digest verification failed"

    echo "Data integrity verification failed." >&2
    exit 1
}

case $EXPECTED_CONTENT_DIGEST in
"")
    # Digest is not specified
    if [ -n "${HTTP_WANT_CONTENT_DIGEST-}" ]; then
        # Allow a client to validate digest of the received file.
        REQUEST_CONTENT_DIGEST="$(sha256_digest "$tmpfile")"
    fi
    ;;
sha-256=*)
    ACTUAL_CONTENT_DIGEST="$(sha256_digest "$tmpfile")"
    if [ "$EXPECTED_CONTENT_DIGEST" != "$ACTUAL_CONTENT_DIGEST" ]; then
        digest_verification_failed
    fi
    ;;
*)
    # Unsupported digest algorithm
    digest_verification_failed
    ;;
esac

# -----------------------------------------------------------------------------
# Transform the received file
# -----------------------------------------------------------------------------

"$@" "$tmpfile" 1>&2

# -----------------------------------------------------------------------------
# Send the transformed file back
# -----------------------------------------------------------------------------

# Calculate content digest for integrity verification.
RES_CONTENT_DIGEST="$(sha256_digest "$tmpfile")"

# Compress the file content before sending.
if printf '%s\n' "$HTTP_ACCEPT_ENCODING" | grep -qiE '(^|,)[[:space:]]*zstd[[:space:]]*(,|$)' && command -v zstd >/dev/null 2>&1; then
    # zstd compression
    RES_CONTENT_ENCODING=zstd
    resfile="$(mktemp -t cgi-file-transform.zstd.XXXXXX)"
    zstd "$tmpfile" -f -o "$resfile"
elif printf '%s\n' "$HTTP_ACCEPT_ENCODING" | grep -qiE '(^|,)[[:space:]]*gzip[[:space:]]*(,|$)'; then
    # gzip compression
    RES_CONTENT_ENCODING=gzip
    resfile="$(mktemp -t cgi-file-transform.gzip.XXXXXX)"
    gzip -c "$tmpfile" >"$resfile"
else
    # No compression
    RES_CONTENT_ENCODING=
    resfile="$tmpfile"
    unset tmpfile
fi

# Start transmitting HTTP response at the very end so that a client can detect
# errors that occured before this point.
echo "$SERVER_PROTOCOL 200 OK"

# Send HTTP headers.
echo "Content-Type: application/octet-stream"
if [ -n "$RES_CONTENT_ENCODING" ]; then
    echo "Content-Encoding: $RES_CONTENT_ENCODING"
fi
# Specify content length for improved communication reliability.
echo "Content-Length: $(wc -c <"$resfile")"
# Integrity verification data.
echo "Content-Digest: $RES_CONTENT_DIGEST"
if [ -n "${REQUEST_CONTENT_DIGEST-}" ]; then
    echo "X-Request-Content-Digest: $REQUEST_CONTENT_DIGEST"
fi

echo

# Send the HTTP content.
cat "$resfile"
