# Adhoc File Signer Server

The server provides a secure HTTP endpoint for file signing, supporting both hardware security modules (HSMs) and password-protected certificate files.

Clients interact with the server using the [Adhoc File Signer Client Tools](https://github.com/gapotchenko/adhoc-file-signer/tree/main/source/client).

## Overview

The HTTP frontend is implemented in Deno and executes CGI scripts to handle requests.
This design isolates the core logic in standalone scripts while ensuring secure interaction with clients through a controlled process model.

Client authorization is implemented via a simple API key mechanism.
For secure communication, the server is intended to run behind a TLS-terminating HTTP proxy, which provides traffic encryption.


## Installation

The server is available from the
[project releases page](https://github.com/gapotchenko/adhoc-file-signer/releases).
It is distributed as a portable archive:

```
adhoc-file-signer-X.Y.Z-server-portable.tar.gz
```

Once the archive is unpacked to a dedicated directory, the server is ready to use.

## Requirements

Adhoc File Signer Server requires the following tools to be available on the command line:

1. [Deno](https://deno.com/) 2.5+
2. [zstd](https://github.com/facebook/zstd) (optional; provides more efficient data compression when available)

The server runs in a POSIX environment, which makes the implementation cross-platform by design.
On Unix-like systems, POSIX is available by default.
On Windows, the server relies on [GNU-TK](https://github.com/gapotchenko/gnu-tk) to provide this environment.

## Getting Started

Follow the initial steps:

1. **Define server configuration** in environment variables:

   ```sh
   # Certificate parameters
   export GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE="my-company.p12"
   export GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD="cert-secret"

   # Signing parameters
   export GP_ADHOC_FILE_SIGNER_FILE_DIGEST="sha256"

   # Timestamping parameters
   export GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER="http://timestamp.digicert.com/"
   export GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST="sha256"

   # Access parameters
   export GP_ADHOC_FILE_SIGNER_API_KEY="123456"
   ```

2. **Run** the server:

   ```sh
   cd bin
   ./adhoc-sign-server
   ```

If everything is ok, you will see the output like this:

```
adhoc-sign-server  Version X.Y.Z
Validating configuration...
Host environment: MS/Windows
Starting HTTP server...
deno serve: Listening on http://[::1]:3205/
```

Now you can connect to the server with the [client tools](https://github.com/gapotchenko/adhoc-file-signer/tree/main/source/client).

## Configuration

### Certificate Parameters

The certificate parameters define which certificate is used for digital signing.
Two types of certificates are supported:

- **Certificates with both public and private keys (PKCS#12 certificates)**\
  These are self-contained certificates, typically stored as `.p12`/`.pfx` files and protected by a password.
- **Certificates with only a public key (public certificates)**\
  These are represented as `.cer` files in DER format. Since the private key is not included, its functionality must be provided separately - commonly by an HSM.

The certificate and related information are provided by your certification authority.

#### Option 1. PKCS#12 Certificate (Public + Private Keys)

To configure a PKCS#12 certificate, the following environment variables should be set:

- `GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE` — path to the `.p12`/`.pfx` certificate file in PKCS#12 format
- `GP_ADHOC_FILE_SIGNER_CERTIFICATE_PASSWORD` — password protecting the certificate

#### Option 2. Public Certificate (Public Key Only)

To configure a public certificate, the following environment variables should be set:

- `GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE` — path to the `.cer` certificate file in DER format

When using a public certificate, the private key functionality must be provided by another component (for example, an HSM).
Certificate parameteres should point to that component in one way or another:
  
- `GP_ADHOC_FILE_SIGNER_CSP` — configuration service provider providing a private key container
- `GP_ADHOC_FILE_SIGNER_KEY_CONTAINER` — key container name of the private key

### Signing Parameters

To configure digital signing, the following environment variables should be set:

- `GP_ADHOC_FILE_SIGNER_FILE_DIGEST` — digest algorithm to use for creating file signatures (for example: `sha256`, `sha384`)

### Timestamping Parameters

Digital timestamping can be configured using the following environment variables:

- `GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER` — RFC 3161 timestamp server URL; if omitted, signed files will not be timestamped
- `GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST` — digest algorithm to use for timestamps

Timestamps provide cryptographic proof that a signature was applied at a specific point in time.
They ensure that signatures remain valid even after the signing certificate has expired.
