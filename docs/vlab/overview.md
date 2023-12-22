# Overview

It's possible to run Hedgehog Fabric in a fully virtual environment using QEMU/KVM and SONiC Virtual Switch (VS). It's
a great way to try out Fabric and learn about its looka and feel, API, capabilities and etc. It's not suitable for any
data plane or performance testing as well as not for production use.

In the VLAB all switches will start as an empty VMs with only ONiE image on them and will go through the whole
discovery, boot and installation process like on the real hardware.

## Overview

The `hhfab` CLI provides a special command `vlab` to manage the virtual labs. It allows to run set of virtual machines
to simulate the Fabric infrastructure including control node, switches, test servers and automatically runs installer
to get Fabric up and running.

You can find more information about getting `hhfab` in the [download](../getting-started/download.md) section.

## System Requirements

Currently, it's only tested on Ubuntu 22.04 LTS, but should work on any Linux distribution with QEMU/KVM support and fairly
up-to-date packages.

Following packages needs to be installed: `qemu-kvm swtpm-tools tpm2-tools socat` and docker will be required to login
into OCI registry.

By default, VLAB topology is Spine-Leaf with 2 spines, 2 MCLAG leafs and 1 non-MCLAG leaf. Optionally, you can choose
to run default Collapsed Core topology using `--fabric-mode collapsed-core` (or `-m collapsed-core`) flag which only
conisists of 2 switches.

You can calculate the system requirements based on the allocated resources to the VMs using the following table:

| Device | vCPU | RAM | Disk |
| --- | --- | --- | --- |
| Control Node | 6 | 6GB | 100GB |
| Test Server | 2 | 768MB | 10GB |
| Switch | 4 | 5GB | 50GB |

Which gives approximately the following requirements for the default topologies:

* Spine-Leaf: 38 vCPUs, 36352 MB, 410 GB disk
* Collapsed Core: 22 vCPUs, 19456 MB, 240 GB disk

Usually, non of the VMs will reach 100% utilization of the allocated resources, but as a rule of thumb you should make
sure that you have at least allocated RAM and disk space for all VMs.

NVMe SSD for VM disks is highly recommended.

## Installing prerequisites

On Ubuntu 22.04 LTS you can install all required packages using the following commands:

```bash
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

```bash
sudo apt install -y qemu-kvm swtpm-tools tpm2-tools socat
sudo usermod -aG kvm $USER
newgrp kvm
kvm-ok
```

Good output of the `kvm-ok` command should look like this:

```
ubuntu@docs:~$ kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used
```
