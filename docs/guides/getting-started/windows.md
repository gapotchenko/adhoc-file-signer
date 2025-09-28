# Getting Started with Adhoc File Signer on Windows

This document will guide you through the basic installation and configuration of Adhoc File Signer on Windows.

## HSM

**HSM** abbreviation stands for _Hardware Security Module_.

Recently, the code signing industry has shifted toward the exclusive use of HSMs for storing sensitive cryptographic material.
If you obtain a code signing certificate in 2025, it will likely be issued with an HSM device similar to the one shown below:

![SafeNet 5110 HSM with USB interface](assets/safenet-5110-hsm.webp)

Figure 1. SafeNet 5110 HSM with USB 2.0 interface

Each HSM is accompanied by client software. Once installed on Windows, this software makes the corresponding code signing certificate available in the **User Certificate Store**, which is managed by the operating system.

After the certificate is available in the store, any program on that machine can use it to sign files.

But what if you operate multiple build servers distributed across the globe?
They all need access to the code signing certificate — yet the certificate is only usable on the local machine where the HSM is physically connected.

To solve this challenge, you need software that securely exposes the signing capability to authorized remote clients.
This is exactly what **Adhoc File Signer Server** does: it uses the locally available certificate to process client signing requests in a secure manner.
