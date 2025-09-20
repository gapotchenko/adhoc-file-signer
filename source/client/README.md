# Adhoc File Signer Client Tools

The client tools provide functionality for interacting with Adhoc File Signer Server.

## adhoc-sign-tool

`adhoc-sign-tool` command-line utility provides the file signing and diagnostic capabilities.
This is how it can be used:

```
Usage:
  adhoc-sign-tool sign --server <server-url> -k <api-key> <file...>
                       [--dry] [--verbose]
  adhoc-sign-tool echo --server <server-url> -k <api-key> <file...>
                       [--verbose]
  adhoc-sign-tool ping --server <server-url> -k <api-key> [--verbose]

Commands:
  sign  Sign the specified file(s) using the server.
  echo  Send the specified file(s) to the server and recieve them back
        unmodified. Useful for testing connectivity and data transfer.
  ping  Ping the server using its API. Useful for testing connectivity and
        verifying authorization.

Options:
  --server      The server URL. If omitted, the value of
                GP_ADHOC_FILE_SIGNER_SERVER environment variable is used.
  -k --api-key  The API authorization key. If omitted, the value of
                GP_ADHOC_FILE_SIGNER_API_KEY environment variable is used.
  --verbose     Enable verbose output.
  --dry         Perform a dry run without applying any modifications.
```

