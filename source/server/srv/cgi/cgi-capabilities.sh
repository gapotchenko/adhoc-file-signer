#!/bin/sh

# cgi-capabilities.sh - gets CGI server capabilities.

set -eu

# Determine which encodings are supported by the server.
RESPONSE_ACCEPT_ENCODING=gzip
# The list depends on tools availability.
if command -v zstd >/dev/null 2>&1; then
    RESPONSE_ACCEPT_ENCODING="$RESPONSE_ACCEPT_ENCODING, zstd"
fi

# Start transmitting HTTP response at the very end so that a client can detect
# errors that occured before this point.
echo "$SERVER_PROTOCOL 200 OK"

# Send HTTP headers.
echo "Content-Type: text/plain;charset=utf-8"
echo "Content-Length: 0"

if [ -n "$RESPONSE_ACCEPT_ENCODING" ]; then
    # Sending this header in a server response is not part of standard HTTP
    # semantics. However, we reuse the name of the standard request header to
    # indicate the same purpose on the server side: communicating the supported
    # encodings.
    echo "Accept-Encoding: $RESPONSE_ACCEPT_ENCODING"
fi

echo

# No HTTP content to send.
