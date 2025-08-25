# Download

The main entry point for the software is the Hedgehog Fabricator CLI named `hhfab`. It is a command-line tool that
allows to build installer for the Hedgehog Fabric, upgrade the existing installation, or run the Virtual LAB.

## Getting access

The instructions in the [Downloading hhfab](#downloading-hhfab) section below can be used to download the hhfab utility - however, the virtual lab (VLAB) features include assets which require a signed agreement and a authentication token to access. 

To access the vlab features, please submit a request on the [Hedgehog Download Page](https://hedgehog.cloud/download) and once approved, you will recieve an email with download instructions.

Once you have recieved the email with your credentials, log in to the registry using the following command:

```bash
docker login ghcr.io --username provided_user_name --password provided_token_string
```

## Downloading hhfab

Currently `hhfab` is supported on Linux x86/arm64 (continuously tested on Ubuntu 24.04) and MacOS x86/arm64 (latest
major release) for building installers/upgraders. It *may* work on Windows WSL2 (with Ubuntu), but it's not tested.
For running VLAB only Linux x86 is currently supported (continuously tested on Ubuntu 24.04).

All software is published into the OCI registry [GitHub Package](https://ghcr.io) including binaries, container images, or Helm charts.
Download the latest stable `hhfab` binary from the [GitHub Package](https://ghcr.io) using the following command, it requires ORAS to be installed (see below):

```bash
curl -fsSL https://i.hhdev.io/hhfab | bash
```

Or download a specific version (e.g. 24.09) using the following command:

```bash
curl -fsSL https://i.hhdev.io/hhfab | VERSION=24.09 bash
```

Use the `VERSION` environment variable to specify the version of the software to download. By default, the latest stable
release is downloaded. You can pick a specific release series (e.g. `25.01`) or a specific release.

The default location for `hhfab` installation is `/usr/local/bin`. The location
can be changed by setting the `INSTALL_DIR` environment variable that is
provided to the `hhfab` install script. Changing the installation directory is
necessary if these commands are being run on the control node, `/usr` is not
writable.

```bash
curl -fsSL https://i.hhdev.io/hhfab | INSTALL_DIR=. bash
```

### Installing ORAS

The download script requires [ORAS](https://oras.land/) to be installed. ORAS is used to download the binary from the
OCI registry and can be installed using following command:

```bash
curl -fsSL https://i.hhdev.io/oras | bash
```

## Next steps

* [Concepts](../concepts/overview.md)
* [Virtual LAB](../vlab/overview.md)
* [Installation](../install-upgrade/install.md)
* [User guide](../user-guide/overview.md)
