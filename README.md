# Adhoc File Signer

**adhoc-file-signer** is a minimalistic self-hosted tool for distributed, automated file signing.
Despite its small size, it provides full support for Authenticode (Windows binaries) and PKCS#11 (hardware tokens and HSMs),
making it well-suited for CI/CD pipelines and build environments.

The architecture of `adhoc-file-signer` follows the Unix philosophy, assembling small, reliable components into a configurable and extensible system.

The project consists of two main components:

- **Client:** the `adhoc-sign-tool` command-line utility
- **Server:** an HTTP service that performs the actual signing using a hardware token, HSM, or a certificate file


