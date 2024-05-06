# Download

## Getting access

Prior to General Availability, access to the full software is limited and requires Design Partner Agreement.
Please submit a ticket with the request using [Hedgehog Support Portal](https://support.githedgehog.com/).

After that you will be provided with the credentials to access the software on [GitHub Package](https://ghcr.io).
In order to use the software, log in to the registry using the following command:

```bash
docker login ghcr.io
```

## Downloading the software

The main entry point for the software is the Hedgehog Fabricator CLI named `hhfab`. All software is published into the
OCI registry [GitHub Package](https://ghcr.io) including binaries, container images, or Helm charts.
Download the latest stable `hhfab` binary from the [GitHub Package](https://ghcr.io) using the following command:

```bash
curl -fsSL https://i.hhdev.io/hhfab | bash
```

Or download a specific version using the following command:

```bash
curl -fsSL https://i.hhdev.io/hhfab | VERSION=alpha-X bash
```

Use the `VERSION` environment variable to specify the version of the software to download. By default, the latest
release is downloaded. You can pick a specific release series (e.g. `alpha-2`) or a specific release.

The download script requires [ORAS](https://oras.land/) to be installed. ORAS is used to download the binary from the
OCI registry and can be installed using following command:

```bash
curl -fsSL https://i.hhdev.io/oras | bash
```

Currently only Linux x86 is supported for running `hhfab`.

## Next steps

* [Concepts](../concepts/overview.md)
* [Virtual LAB](../vlab/overview.md)
* [Installation](../install-upgrade/overview.md)
* [User guide](../user-guide/overview.md)
