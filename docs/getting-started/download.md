# Download

The main entry point for the software is the Hedgehog Fabricator CLI named `hhfab`. It is a command-line tool that
allows to build installer for the Hedgehog Fabric, upgrade the existing installation, or run the Virtual LAB.

## Getting access

Prior to General Availability, access to the full software is limited and requires Design Partner Agreement.
Please submit a ticket with the request using [Hedgehog Support Portal](https://support.githedgehog.com/).

After that you will be provided with the credentials to access the software on [GitHub Package](https://ghcr.io).
In order to use the software, log in to the registry using the following command:

```bash
docker login ghcr.io --username provided_user_name --password provided_token_string
```

## Downloading hhfab

Currently `hhfab` is supported on Linux x86/arm64 (tested on Ubuntu 22.04) and MacOS x86/arm64 for building
installers/upgraders. It may work on Windows WSL2 (with Ubuntu), but it's not tested. For running VLAB only Linux x86
is currently supported.

All software is published into the OCI registry [GitHub Package](https://ghcr.io) including binaries, container images, or Helm charts.
Download the latest stable `hhfab` binary from the [GitHub Package](https://ghcr.io) using the following command, it requires ORAS to be installed (see below):

```bash
curl -fsSL https://i.hhdev.io/hhfab | bash
```

Or download a specific version (e.g. beta-1) using the following command:

```bash
curl -fsSL https://i.hhdev.io/hhfab | VERSION=beta-1 bash
```

Use the `VERSION` environment variable to specify the version of the software to download. By default, the latest stable
release is downloaded. You can pick a specific release series (e.g. `alpha-2`) or a specific release.

### Installing ORAS

The download script requires [ORAS](https://oras.land/) to be installed. ORAS is used to download the binary from the
OCI registry and can be installed using following command:

```bash
curl -fsSL https://i.hhdev.io/oras | bash
```

## Next steps

* [Concepts](../concepts/overview.md)
* [Virtual LAB](../vlab/overview.md)
* [Installation](../install-upgrade/overview.md)
* [User guide](../user-guide/overview.md)
