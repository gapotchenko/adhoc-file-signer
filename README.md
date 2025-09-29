# Adhoc File Signer

**adhoc-file-signer** is a minimalistic, self-hosted system for distributed and
automated file signing. Despite its small footprint, it supports Authenticode
(for Windows binaries) and PKCS#11 (for hardware tokens / HSMs), making it a
good enough solution for CI/CD pipelines and secure build environments.

The architecture of `adhoc-file-signer` follows the Unix philosophy by
assembling small tunable components into a configurable and extensible system.

The project consists of two main components:

- **[Client](source/client):** the `adhoc-sign-tool` command-line utility
- **[Server](source/server):** an HTTP service that performs the actual signing
  using an HSM or a password protected certificate file

`adhoc-sign-tool` can then be used in various build environments to sign
produced files without exposing sensitive cryptographic material.

## Getting Started

- [Guide for Windows](docs/guides/getting-started/windows)

## Supported Platforms

- Linux
- macOS
- Windows

## Limitations

While `adhoc-file-signer` provides many benefits, its simple architecture also
introduces several constraints:

- **File transmission:** Each file must be sent in full to the server for
  signing which is a brute-force approach. A more advanced design would allow
  signing to happen locally, with the server acting only as a remote HSM. This
  would reduce client-server traffic by several orders of magnitude making it ~5000× less.

- **Authentication:** Currently, authorization is limited to a basic API key
  mechanism.

- **Networking:** To be accessible globally, the `adhoc-file-signer` server must
  be exposed to the internet. Since it lacks built-in encryption (HTTPS) and
  tunneling support (port forwarding), a third-party solution such as
  [Tailscale Funnel](https://tailscale.com/kb/1223/funnel) is required to secure
  the traffic, which may add operational costs over time. Alternatively, you can
  do it yourself by utilizing an intermediate HTTP proxy server with a proper
  TLS termination and WAN port forwarding.
