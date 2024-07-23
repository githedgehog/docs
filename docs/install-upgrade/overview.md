# Install Fabric

!!! warning ""
    Under construction.

## Prerequisites

* Have a machine with access to the Internet to use Fabricator and build installer
* Have a machine to install Fabric Control Node on with enough NICs to connect to at least one switch using Front Panel
  ports and enough CPU and RAM (see [System Requirements](./requirements.md)) as well as IPMI access to it to install
  the OS
* Have enough [Supported Switches](./supported-devices.md) for your Fabric

## Main steps

This chapter is dedicated to the Hedgehog Fabric installation on bare-metal control node(s) and switches, their
preparation and configuration.

Get `hhfab` installed following instructions from the [Download](../getting-started/download.md) section.

The main steps to install Fabric are:

1. Install `hhfab` on the machines with access to the Internet
    1. [Prepare Wiring Diagram](./build-wiring.md)
    1. [Select Fabric Configuration](./config.md)
    1. [Build Control Node configuration and installer](#build-control-node-configuration-and-installer)
1. [Install Control Node](#install-control-node)
    1. Install Flatcar Linux on the Control Node
    1. Upload and run Control Node installer on the Control Node
1. Prepare supported switches
    1. [Install Hedgehog ONIE (HONIE) on them](./onie-update.md)
    1. Reboot them into ONIE Install Mode to have them automatically provisioned

## Build Control Node configuration and installer

It's the only step that requires Internet access, to download artifacts and build the installer.

Once you've prepared the Wiring Diagram, initialize Fabricator by running `hhfab init` command and passing optional
configuration into it as well as wiring diagram file(s) as flags. Additionally, there are a lot of customizations
available as flags, e.g. to setup default credentials, keys and etc. For more details on the command invocation,
refer to `hhfab init --help`.

The `--dev` option activates the development mode which enables default credentials and keys for the Control
Node and switches:

* Default user with passwordless sudo for the Control Node and test servers is `core` with password `HHFab.Admin!`.
* Admin user with full access and passwordless sudo for the switches is `admin` with password `HHFab.Admin!`.
* Read-only, non-sudo user with access only to the switch CLI for the switches is `op` with password `HHFab.Op!`.

Alternatively, you can pass your own credentials and keys using `--authorized-key` and `--control-password-hash` flags.
Generate a password hash with command `openssl passwd -5`. Further customization items are available in the config
file and can be passed using the `--config` flag.

```bash
hhfab init --preset lab --dev --wiring file1.yaml --wiring file2.yaml
hhfab build
```

As a result, you will get the following files in the `.hhfab` directory or the one you've passed using `--basedir` flag:

* `control-os/ignition.json` - ignition config for the Control Node to get OS installed
* `control-install.tgz` - installer for the Control Node, it will be uploaded to the Control Node and run there

More details on configuring the Fabric are available in the [Configuration](./config.md) section.

## Install Control Node

Control Node installation is fully air-gapped and doesn't require Internet access. This control node should be given a static IP address. Either a lease or statically assigned. 

Download the [latest stable Flatcar Container Linux ISO][Flatcar ISO] and boot into it (using IPMI attaching media, USB
stick or any other way).

[Flatcar ISO]: https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_iso_image.iso

Once you've booted into the Flatcar installer, upload the file `ignition.json` built during the previous step to the
system and run the Flatcar installation:

```bash
sudo flatcar-install -d /dev/sda -i ignition.json
```

Where `/dev/sda` is a disk you want to install Control Node to and `ignition.json` is the `control-os/ignition.json`
file from previous step uploaded to the Flatcar installer.

The installation is finished when you see a message similar to the following:

```shell
Installing Ignition config ignition.json...
Success! Flatcar Container Linux stable 3510.2.6 is installed on /dev/sda
```

Once the installation is finished, reboot the machine and wait for it to boot into the installed Flatcar Linux.

At that point, you should get into the installed Flatcar Linux using the dev or provided credentials with user `core`
and you can now install Hedgehog Open Network Fabric on it. Download `control-install.tgz` to the just installed Control
Node (for example, by using scp) and run it.

```bash
tar xzf control-install.tgz && cd control-install && sudo ./hhfab-recipe run
```

The command prints the logs generated while installing Fabric (including logs from the Kubernetes cluster, miscellaneous
OCI registry misc components, and more). At the end, you should observe lines similar to the following:

```
...
01:34:45 INF Running name=reloader-image op="push fabricator/reloader:v1.0.40"
01:34:47 INF Running name=reloader-chart op="push fabricator/charts/reloader:1.0.40"
01:34:47 INF Running name=reloader-install op="file /var/lib/rancher/k3s/server/manifests/hh-reloader-install.yaml"
01:34:47 INF Running name=reloader-wait op="wait deployment/reloader-reloader"
deployment.apps/reloader-reloader condition met
01:35:15 INF Done took=3m39.586394608s
```

At that point, you can start interacting with the Fabric using `kubectl`, `kubectl fabric` and `k9s`, all preinstalled
as part of the Control Node installer.

You can now get HONIE installed on your switches and reboot them into ONIE Install Mode to have them automatically
provisioned from the Control Node.
