# Adhoc File Signer Server

The server provides an HTTP endpoint for file signing, supporting both hardware security modules (HSMs) and password-protected certificate files.

## Overview

The HTTP API frontend is implemented in Deno and executes CGI scripts to handle requests.
This design isolates the core logic in standalone scripts while ensuring secure interaction with clients through a controlled process model.

Client authorization is implemented via a simple API key mechanism.
For secure communication, the server is intended to run behind a TLS-terminating HTTP proxy which provides traffic encryption.


## Installation

The server is available from the
[project releases page](https://github.com/gapotchenko/adhoc-file-signer/releases).
It is distributed as a portable archive:

```
adhoc-file-signer-X.Y.Z-server-portable.tar.gz
```

Once the archive is unpacked to a directory, the server is ready to use.

Adhoc File Signer Server requires the following tools to be available on the command line:

1. [Deno](https://deno.com/) 2.5+
2. [GNU-TK](https://github.com/gapotchenko/gnu-tk) (required only on Windows)
3. [zstd](https://github.com/facebook/zstd) (optional; provides more efficient data compression when available)

The server runs in a POSIX environment which makes the implementation cross-platform by design.
On Unix-like systems, POSIX is available by default.
On Windows, the server relies on GNU-TK to provide this environment.

