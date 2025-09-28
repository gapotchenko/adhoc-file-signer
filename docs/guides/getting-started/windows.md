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

## Choosing a Host Machine

The HSM must be connected to a machine that will run Adhoc File Signer Server.
A convenient option might be to use a virtual machine.
However, support for USB and HSM passthrough in virtualized environments is limited, and even when available, it is often considered experimental without guarantees of actually working.

For this reason, we recommend hosting Adhoc File Signer Server on physical hardware.
The software stack has modest requirements — a system with at least 2 CPU cores and 4 GB of RAM is sufficient.

In this guide, we will use a Dell microcomputer equipped with a 2C/4T 3.5 GHz CPU and 8 GB of RAM:

![Dell OptiPlex Micro 3050](assets/dell-optiplex-3050-micro.webp)

Figure 2. Dell OptiPlex Micro 3050

This model also includes a built-in TPM 2.0 module, which will be used to enable drive encryption after the operating system installation, enhancing overall system security.
