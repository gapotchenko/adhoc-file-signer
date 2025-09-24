#!/bin/sh

# cgi-ping.sh - pings CGI server.

set -eu

# Send HTTP response.
echo "$SERVER_PROTOCOL 200 OK"
echo "Content-Type: text/plain;charset=utf-8"
echo
echo "PING OK"
