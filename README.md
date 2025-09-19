# Adhoc File Signer

**adhoc-file-signer** is a minimalistic, self-hosted tool for distributed and automated file signing.
Despite its small footprint, it supports Authenticode (for Windows binaries) and PKCS#11 (for hardware tokens and HSMs), making it good enough for CI/CD pipelines and secure build environments.

The architecture of `adhoc-file-signer` follows the Unix philosophy by assembling small, reliable components into a configurable and extensible system.

The project consists of two main components:

- **Client:** the `adhoc-sign-tool` command-line utility
- **Server:** an HTTP service that performs the actual signing using a hardware token, HSM, or a certificate file

`adhoc-sign-tool` can then be used in various build environments to sign produced files without exposing sensitive material.

## Limitations

While `adhoc-file-signer` provides many benefits, its simple architecture also introduces several constraints:

- **File transmission:** Each file must be sent in full to the server for signing — a brute-force approach. A more advanced design would allow signing to happen locally, with the server acting only as a remote HSM. This would reduce client-server traffic by several orders of magnitude (up to ~10,000× less on average).

- **Authentication:** Currently, authorization is limited to a basic API key mechanism.

- **Networking:** To be accessible globally, the `adhoc-file-signer` server must be exposed to the internet. Since it lacks built-in encryption (HTTPS) and tunneling (port forwarding), securing traffic requires a third-party solution such as [Tailscale Funnel](https://tailscale.com/kb/1223/funnel), which may add operational costs over time.
