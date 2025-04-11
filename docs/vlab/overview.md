# VLAB Overview

It's possible to run Hedgehog Fabric in a fully virtual environment using QEMU/KVM and SONiC Virtual Switch (VS). It's
a great way to try out Fabric and learn about its look and feel, API, and capabilities. It's not suitable for any
data plane or performance testing, or for production use.

In the VLAB all switches start as empty VMs with only the ONIE image on them, and they go through the whole discovery,
boot and installation process like on real hardware.

## HHFAB

Hedgehog maintains a utility to install and configure VLAB, called `hhfab`, aka Fabricator.

The `hhfab` CLI provides a special command `vlab` to manage the virtual labs. It allows you to run sets of virtual
machines to simulate the Fabric infrastructure including control node, switches, test servers and it automatically runs
the installer to get Fabric up and running.

You can find more information about getting `hhfab` in the [download](../getting-started/download.md) section.

## System Requirements

Currently, it's primarily tested on Ubuntu 24.04 LTS, but should work on any Linux distribution with QEMU/KVM support
and fairly up-to-date packages.

The following packages needs to be installed: `qemu-kvm socat`. Docker is also required, to login
into the OCI registry.

By default, the VLAB topology is Spine-Leaf with 2 spines, 2 MCLAG leaves,
2 ESLAG leaves and 1 non-LAG leaf, plus a virtual external device. Optionally, you can
choose to run the default Collapsed Core topology using flag `--fabric-mode collapsed-core`
(or `-m collapsed-core`) which only consists of 2 switches and the virtual external.
You can also fine tune how many switches, servers and externals are generated via
command line parameters; see `hhfab vlab gen --help` for all the available options.

You can calculate the system requirements based on the allocated resources to the VMs using the following table:

| Device | vCPU | RAM | Disk |
| --- | --- | --- | --- |
| Control Node | 6 | 6GB | 100GB |
| Test Server | 2 | 768MB | 10GB |
| Switch | 4 | 5GB | 50GB |
| Virtual External | 4 | 5GB | 50GB |

These numbers give approximately the following requirements for the default topologies:

* Spine-Leaf: 50 vCPUs, 44544 MB, 500 GB disk
* Collapsed Core: 26 vCPUs, 24576 MB, 290 GB disk

Usually, none of the VMs will reach 100% utilization of the allocated resources, but as a rule of thumb you should make
sure that you have at least allocated RAM and disk space for all VMs.

NVMe SSD for VM disks is highly recommended.

## Installing Prerequisites

To run VLAB, your system needs `docker`,`qemu`,`kvm`, and `hhfab`. On Ubuntu 24.04 LTS you can install all required packages using the following commands:

### Docker

```bash
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### Qemu/KVM
```bash
sudo apt install -y qemu-kvm socat
sudo usermod -aG kvm $USER
newgrp kvm
kvm-ok
```

Good output of the `kvm-ok` command should look like this:

```console
ubuntu@docs:~$ kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used
```

### Oras

For convenience Hedgehog provides a script to install `oras`:

```bash
curl -fsSL https://i.hhdev.io/oras | bash
```

### Hhfab

You need a GitHub access token to download `hhfab`, please submit a ticket using the [Hedgehog Support Portal](https://support.githedgehog.com/). Once in possession of the credentials, use the provided username and token to log into the GitHub container registry:

```bash
docker login ghcr.io --username provided_username --password provided_token
```

Once logged in, download and run the script:

```bash
curl -fsSL https://i.hhdev.io/hhfab | bash
```

## Next steps

* [Configure and Run VLAB](./running.md)
