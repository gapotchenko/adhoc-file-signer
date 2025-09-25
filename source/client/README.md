# Adhoc File Signer Client

The client tools provide functionality for interacting with the
[Adhoc File Signer Server](https://github.com/gapotchenko/adhoc-file-signer/tree/main/source/server).

## Installation

The client tools are available from the
[project releases page](https://github.com/gapotchenko/adhoc-file-signer/releases).
They are distributed as a portable archive:

```
adhoc-file-signer-X.Y.Z-client-portable.tar.gz
```

Once the archive is unpacked, the tools are ready to use.

The tools have no specific prerequisites as they are written using standard-compliant POSIX shell script.
On Windows, you may need to install [GNU-TK](https://github.com/gapotchenko/gnu-tk) first to get seamless access to GNU/POSIX environment.

## Getting Started

1. **Set up environment variables**:

   ```sh
   export GP_ADHOC_FILE_SIGNER_SERVER="https://your-machine.example.ts.net/adhoc-file-signer"
   export GP_ADHOC_FILE_SIGNER_API_KEY="your-api-key"
   ```

   If you prefer not to use environment variables, the corresponding parameters
   must be provided in each command via command-line arguments. See `adhoc-sign-tool --help` for details.

2. **Verify connectivity** with the server:

   ```sh
   adhoc-sign-tool ping
   ```

3. **Test data transfer** without signing:

   ```sh
   adhoc-sign-tool echo example.exe
   ```

4. **Sign your file**:

   ```sh
   adhoc-sign-tool sign example.exe
   ```

## Supported Platforms

- Linux
- macOS
- Windows

## Quick Reference

### adhoc-sign-tool

`adhoc-sign-tool` command-line utility provides file-signing and diagnostic
capabilities.

#### Usage

```
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

To sign a file, run `adhoc-sign-tool` with the appropriate parameters:

```sh
adhoc-sign-tool sign contoso-works.msi
```

For the command to succeed, `adhoc-sign-tool` must know the server URL and API
key. These can be passed as `--server` and `--api-key` command-line options, or alternatively provided via
the environment variables:

- `GP_ADHOC_FILE_SIGNER_SERVER` — the server URL, e.g.
  `https://your-machine.example.ts.net/adhoc-file-signer`
- `GP_ADHOC_FILE_SIGNER_API_KEY` — the API key authorized by the server
