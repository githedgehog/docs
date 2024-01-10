<!--@@joggrdoc@@-->
<!-- @joggr:version(v1):end -->
<!-- @joggr:warning:start -->
<!-- 
  _   _   _    __        __     _      ____    _   _   ___   _   _    ____     _   _   _ 
 | | | | | |   \ \      / /    / \    |  _ \  | \ | | |_ _| | \ | |  / ___|   | | | | | |
 | | | | | |    \ \ /\ / /    / _ \   | |_) | |  \| |  | |  |  \| | | |  _    | | | | | |
 |_| |_| |_|     \ V  V /    / ___ \  |  _ <  | |\  |  | |  | |\  | | |_| |   |_| |_| |_|
 (_) (_) (_)      \_/\_/    /_/   \_\ |_| \_\ |_| \_| |___| |_| \_|  \____|   (_) (_) (_)
                                                              
This document is managed by Joggr. Editing this document could break Joggr's core features, i.e. our 
ability to auto-maintain this document. Please use the Joggr editor to edit this document 
(link at bottom of the page).
-->
<!-- @joggr:warning:end -->
# Download

## Getting access

Prior to the General Availability, access to the full software is limited and requires Design Partner Agreement.
Please submit a ticket with the request using [Hedgehog Support Portal](https://support.githedgehog.com/).

After that you will be provided with the credentials to access the software on [GitHub Package](https://ghcr.io).
In order to use it you need to login to the registry using the following command:

```bash
docker login ghcr.io
```

## Downloading the software

The main entry point for the software is the Hedgehog Fabricator CLI named `hhfab`. All software is published into the
OCI registry [GitHub Package](https://ghcr.io) including binaries, container images, helm charts and etc.
The `hhfab` binary can be downloaded from the [GitHub Package](https://ghcr.io) using the following command:

```bash
curl -fsSL https://i.hhdev.io/hhfab | VERSION=alpha-2 bash
```

The `VERSION` environment variable can be used to specify the version of the software to download. If it's not specified
the latest release will be downloaded. You can pick specific release series (e.g. `alpha-2`) or specific release.

It requires [ORAS](https://oras.land/) to be installed which is used to download the binary from the OCI registry and
could be installed using following command:

```bash
curl -fsSL https://i.hhdev.io/oras | bash
```

Currently only Linux x86 is supported for running `hhfab`.

<!-- @joggr:editLink(a87a556b-5207-4e90-9bbc-51b90f44b5c4):start -->
---
<a href="https://app.joggr.io/app/documents/a87a556b-5207-4e90-9bbc-51b90f44b5c4/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(a87a556b-5207-4e90-9bbc-51b90f44b5c4):end -->