# Adhoc File Signer

**adhoc-file-signer** is a minimalistic, self-hosted tool for distributed and automated file signing.
Despite its small footprint, it supports Authenticode (for Windows binaries) and PKCS#11 (for hardware tokens and HSMs), making it good enough for CI/CD pipelines and secure build environments.

The architecture of `adhoc-file-signer` follows the Unix philosophy, assembling small, reliable components into a configurable and extensible system.

The project consists of two main components:

- **Client:** the `adhoc-sign-tool` command-line utility
- **Server:** an HTTP service that performs the actual signing using a hardware token, HSM, or a certificate file

`adhoc-sign-tool` can then be used in various build environments to sign produced files without disclosing the actual file signing material.
