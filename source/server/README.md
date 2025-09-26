# Adhoc File Signer Server

The server exposes an HTTP endpoint for file signing, supporting both hardware security modules (HSMs) and password-protected certificate files.

## Installation

The server is available from the
[project releases page](https://github.com/gapotchenko/adhoc-file-signer/releases).
It is distributed as a portable archive:

```
adhoc-file-signer-X.Y.Z-server-portable.tar.gz
```

Once the archive is unpacked, the server is ready to use.

Adhoc File Signer Server requires the following tools to be available on the command line:

1. [Deno](https://deno.com/)
2. [GNU-TK](https://github.com/gapotchenko/gnu-tk) (required only on Windows)

The server runs in a POSIX environment, which makes the implementation cross-platform by design.
On Unix-like systems, POSIX is available by default.
On Windows, the server relies on GNU-TK to provide this environment.
