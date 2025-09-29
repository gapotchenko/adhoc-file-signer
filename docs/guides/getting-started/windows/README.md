# Getting Started with Adhoc File Signer on Windows

This tutorial will guide you through the basic installation and configuration of
Adhoc File Signer on Windows.

## HSM

**HSM** abbreviation stands for _Hardware Security Module_.

Recently, the code signing industry has shifted toward the exclusive use of HSMs
for storing sensitive cryptographic material. If you obtain a code signing
certificate after 2022, it will likely be issued with an HSM device similar to
the one shown below:

![SafeNet 5110 HSM with USB interface](../assets/safenet-5110-hsm.webp)

Figure 1. SafeNet 5110 HSM with USB 2.0 interface

Each HSM type is accompanied by client software. Once installed on Windows, this
software makes the corresponding code signing certificate available in the
**User Certificate Store**, which is managed by the operating system.

After the certificate is available in the store, any program on that machine can
use it to sign files.

But what if you operate multiple build servers distributed across the globe?
They all need access to the code signing certificate — yet the certificate is
only usable on the local machine where the HSM is physically connected.

To solve this challenge, you need software that securely exposes the signing
capability to authorized remote clients. This is exactly what **Adhoc File
Signer Server** does: it uses the locally available certificate to fulfill
client signing requests in a secure manner.

## Choosing a Host Machine

The HSM must be connected to a machine that will run Adhoc File Signer Server. A
convenient option might be to use a virtual machine. However, support for USB
and HSM passthrough in virtualized environments is limited, and even when
available, it is often considered experimental without guarantees of actually
working.

For this reason, we recommend hosting Adhoc File Signer Server on physical
hardware. The software stack has modest requirements — a system with at least 2
CPU cores and 4 GB of RAM is sufficient.

In this guide, we will use a Dell computer equipped with a 2C/4T 3.5 GHz CPU and
8 GB of RAM:

![Dell OptiPlex Micro 3050](../assets/dell-optiplex-3050-micro.webp)

Figure 2. Dell OptiPlex Micro 3050 computer

This model also includes a built-in TPM 2.0 module, which will be used to enable
drive encryption after the operating system installation, enhancing overall
system security.

## Operating System Configuration

We will use **Windows Server 2025** as the operating system for this setup.

After installation, BitLocker drive encryption should be enabled on the system
drive (`C:\`) to protect data at rest. This step is essential to prevent
unauthorized reuse of the HSM in the event of device theft.

To run Adhoc File Signer Server, it is strongly recommended to use a dedicated
user account. This minimizes the risk of interference with the HSM auto-logon
process which will be discussed later. We create a new user account named
`AppServer`, with no administrative privileges, intended primarily for running
unattended services.

## Software Prerequisites

The following software packages should be installed first:

- [Deno](https://deno.com/) — provides secure JavaScript runtime
- [GNU-TK](https://github.com/gapotchenko/gnu-tk) — provides POSIX environment
  needed by the server. Use MSI installation method to install GNU-TK on the
  server machine.
- [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/)
  — provides `signtool` utility which is neccessary for signing files with
  Authenticode signature. This is the only SDK component that is required, other
  components are not needed by the server and thus are optional.

### Optional Components

- [NuGet](https://www.nuget.org/) — provides functionality for signing NuGet
  packages which are represented by `.nupkg` files. There are three ways to
  install NuGet:
  - It comes as integral part of
    [.NET SDK](https://dotnet.microsoft.com/en-us/download/dotnet)
  - Standalone executable file `nuget.exe` can be separately
    [downloaded](https://www.nuget.org/downloads) and placed at
    `C:\Server\usr\bin` directory (see below)
  - Via [winget](https://winget.run/pkg/Microsoft/NuGet)
- [zstd](https://github.com/facebook/zstd) — provides more efficient data
  compression optimizing both speed and size. `zstd.exe` file can be placed at
  `C:\Server\usr\bin` directory.

## Adhoc File Signer Server Installation

The server software is available from the
[project releases page](https://github.com/gapotchenko/adhoc-file-signer/releases).
It is distributed as a portable archive:

```
adhoc-file-signer-X.Y.Z-server-portable.tar.gz
```

Once archive is downloaded, its contents should be unpacked to a dedicated
directory on the file system.

Let's prepare the directory. We start with a root directory that will contain
our app service(s):

```
C:\Server
```

We assign the `AppServer` user as the owner of the `C:\Server` directory. We
also can add other users and groups with corresponding permissions to ease the
administration.

Now, let's create an initial structure of the newly created directory according
to POSIX conventions:

- `C:\Server\bin` — contains executable files (control scripts in our case)
- `C:\Server\opt` — contains installable components
- `C:\Server\usr\bin` — contains 3rd party executable files

After that, we can extract the contents of
`adhoc-file-signer-X.Y.Z-server-portable.tar.gz` archive into
`C:\Server\opt\adhoc-file-signer` directory.

Now let's create a control script which orchestrates the app services. Create
`C:\Server\bin\run.sh` file with the following content (important: use `LF`
character as a new line separator in `.sh` files, not `CRLF`):

```sh
#!/bin/sh

set -eu

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

export TERM=dumb
export NO_COLOR=true
export PATH="$PATH:$BASE_DIR/usr/bin"

opt/adhoc-file-signer/bin/adhoc-sign-server --host 127.0.0.1 2>&1
```

For now, all this script does is configures the process environment and passes
control to `adhoc-sign-server` demanding it to bind to the IPv4 local network
interface `127.0.0.1`.

You may notice that we use a POSIX shell script in Windows which, at first, may
throw you into a loop. The reason we are doing so is to have a single codebase
for all supported operating systems. To rectify the mismatch between Windows and
POSIX environments, we rely on [GNU-TK](https://github.com/gapotchenko/gnu-tk).

Let's create a bridge script file `C:\Server\bin\run.bat` that will be
seamlessly executing its POSIX counterpart `C:\Server\bin\run.sh`:

```bat
@echo off
rem https://github.com/gapotchenko/gnu-tk
gnu-tk -i -x "%~dpn0.sh" %*
```

If we run `C:\Server\bin\run.bat` script now, we should get the following
output:

```
adhoc-sign-server  Version X.Y.Z
Checking prerequisites...
Validating configuration...
adhoc-sign-server: GP_ADHOC_FILE_SIGNER_API environment variable is not set.
```

This happens because the configuration for `adhoc-sign-server` is yet to be
provided.

## HSM Configuration

HSMs are typically preconfigured by the certification authority, which also
provides the initial setup instructions.

Before using an HSM with Adhoc File Signer Server, you should first verify that
it is functioning correctly. Log in to the machine with the user account that
will regularly access the HSM. In our setup, this is the `AppServer` account.

> [!NOTE]
> HSMs connected directly to a remote machine cannot be accessed over a Remote
> Desktop session. You must have physical access to the system with a locally
> attached display and keyboard.
>
> One possible workaround is to connect the HSM to the client machine initiating
> the Remote Desktop session. In this case, the locally attached HSM can be
> redirected and made available on the remote system.

Then, try to sign a file using `signtool` utility. Typically, you will be asked
for a password by HSM software running in the system. This step is known as
**HSM logon**. Without a successful logon, cryptographic operations provided by
the HSM are unavailable.

> [!CAUTION]
> Be careful when entering the password: most HSMs allow only a limited number of consecutive failed logon attempts (typically 3–15).
> Exceeding this limit will lock the device, requiring intervention from the certification authority to restore access.

By default, an HSM logon is required for each cryptographic operation.
In a server context, however, it is necessary to perform the logon automatically and persist it for longer.
This behavior can be configured using specific HSM parameters.

For example, many HSMs allow logon persistence to be adjusted through their management software.
Some models also support specifying the logon password programmatically using specifically crafted configuration parameters.

Once you confirm that the HSM you have is working, you can start gathering its
configuration parameters. The HSM parameters needed by `adhoc-sign-server` are:

1. `GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE` — public certificate file
2. `GP_ADHOC_FILE_SIGNER_CSP` — CSP offering the private key container
3. `GP_ADHOC_FILE_SIGNER_KEY_CONTAINER` — the private key container name

The configuration parameters can typically be found and extracted using HSM
management software and **User Certificate Store** in Windows. The exact procedure depends
on a particular HSM type.

- **SafeNet HSM:** https://stackoverflow.com/a/54439759

## Configuration of Adhoc File Signer Server

Once you have the HSM configuration at hand, it is time to define a complete
configuration for `adhoc-sign-server`:

| Name                                  | Value                            | Example |
| :------------------------------------ | :------------------------------- | :--- |
| GP_ADHOC_FILE_SIGNER_CERTIFICATE_FILE | Retrieved at the previous step.  | `C:\Users\AppServer\Documents\HSM\Certificate.cer` |
| GP_ADHOC_FILE_SIGNER_CSP              | Retrieved at the previous step.  | `eToken Base Cryptographic Provider` |
| GP_ADHOC_FILE_SIGNER_KEY_CONTAINER    | Retrieved at the previous step.  | `[{{XXXXXX}}]=Sectigo_YYYYMMDDnnnnnn` |
| GP_ADHOC_FILE_SIGNER_FILE_DIGEST      | `sha256`                         | |
| GP_ADHOC_FILE_SIGNER_TIMESTAMP_SERVER | `http://timestamp.digicert.com/` | |
| GP_ADHOC_FILE_SIGNER_TIMESTAMP_DIGEST | `sha256`                         | |
| GP_ADHOC_FILE_SIGNER_API_KEY          | `your-secret-api-key`            | |

In our setup, these environment variables should be set for `AppServer` user.

## Test Run

Once the server is installed and configured, you can now try to run
`C:\Server\bin\run.bat` script as `AppServer` user. This time, it should enter
the running state:

```
adhoc-sign-server  Version X.Y.Z
Checking prerequisites...
Validating configuration...
Host environment: MS/Windows
HSM: initialization started...
HSM: SafeNet Authentication Client (SAC) is installed at 'C:\Program Files\SafeNet\Authentication\SAC'.
HSM: launching SAC Monitor to propagate HSM certificates to a certificate store.
HSM: initialization done.
Starting HTTP server...
deno serve: Listening on http://127.0.0.1:3205/
```

You can then use
[client tools](https://github.com/gapotchenko/adhoc-file-signer/tree/main/source/client)
to interact with the locally running server. For example, to sign a file:

```sh
adhoc-sign-tool sign --server http://127.0.0.1:3205/adhoc-file-signer example.exe
```

If everything is ok, you will get the following output from `adhoc-sign-tool`:

```
Connecting to server...
Server connection established.
Signing file 'example.exe'...
Files have been signed successfully.
```

## Making the Server Globally Available

Once the server is running locally, you may want to expose it to the internet for global access.
A convenient way to achieve this is by using [Tailscale VPN](https://tailscale.com/) and its [Funnel](https://tailscale.com/kb/1223/funnel) feature.

Funnel creates a secure tunnel between you local server and the internet, providing a publicly accessible HTTPS endpoint that can be used to reach the Adhoc File Signer Server from anywhere.

After installing and configuring Tailscale on your server, `tailscale` CLI utility becomes available.
You can use it to establish a funnel for the local port 3205 (the port where `adhoc-sign-server` listens for incoming HTTP requests):

```sh
tailscale funnel 3205
```

`tailscale` should produce the output similar to:

```
Available on the internet:

https://NNNNNN.tailXXXXXX.ts.net/
|-- proxy http://127.0.0.1:3205
```

Write down that `https://NNNNNN.tailXXXXXX.ts.net/` funnel address produced by `tailscale` tool.
This is the part of URL you will be using for accessing the Adhoc File Signer Server globally:

```
https://NNNNNN.tailXXXXXX.ts.net/adhoc-file-signer
```

Once the funnel is running, you can test server connectivity from anywhere in the world:

```sh
adhoc-sign-tool ping --server https://NNNNNN.tailXXXXXX.ts.net/adhoc-file-signer --api-key your-secret-api-key
```

It should produce the following output:

```
Connecting to server...
Server connection established.
PING OK
```

Note that the funnel is active as long as `tailscale funnel` command is running.

## Stitching the App Services Together

Next, let's update the `C:\Server\bin\run.sh` script so that a Tailscale funnel is automatically established each time the server starts:

```sh
#!/bin/sh

set -eu

SCRIPT_DIR="$(dirname "$(readlink -fn -- "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BASE_DIR"

export TERM=dumb
export NO_COLOR=true
export PATH="$PATH:$BASE_DIR/usr/bin"

# Run Tailscale funnel in the background.
tailscale funnel 3205 &

opt/adhoc-file-signer/bin/adhoc-sign-server --host 127.0.0.1 2>&1
```

With this script in place, the server can be registered as a Windows service running under the `AppServer` user account.
This can be accomplished using a service wrapper such as [WinSW](https://github.com/winsw/winsw).

## Template

To aid with server configuration, this guide provides a [template](template) that you can use as a reference.

## Epilogue

By the end of this guide, you should have a fully operational Adhoc File Signer Server that runs unattended, survives reboots, and provides signing capabilities to authorized clients.
HSM logon should also be fully automated at this point, requiring no manual intervention.


