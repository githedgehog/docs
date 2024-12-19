# Upgrade

## Upgrades from Beta-1 onwards

Starting with Beta-1 release and onwards, the upgrade process is more streamlined and fully automated. The control node
is upgraded in place and the agents/switches is upgraded using the control node.

In order to apply the upgrade, the following steps need to be followed:

- use the `hhfab` directory from the initial deployment or init the new one using the configs from the running installation
- run `hhfab build --mode=manual` to generate fully self-contained (airgap) upgrade package
  - for control node named `control-1` it will be `result/control-1-install.tgz`
- upload it to the control node (e.g. using `scp`)
- unpack and run `hhfab-recipe control upgrade` from the resulting directory

```bash
tar xzf control-1-install.tgz
cd control-1-install
./hhfab-recipe control upgrade
```

It'll do all necessary steps to upgrade the control node and the agents/switches. Resulting version could be checked
using `kubectl -n fab get fab/default -o=jsonpath='{.status.versions.fabricator.controller}'` and compare to the
fabricator version in the release notes.

Upgrade process is idempotent and can be run multiple times without any issues.

### Init hhfab dir from the running installation

If the original `hhfab` directory is no longer available, it is possible to export the current configuration from the
running installation and init the new `hhfab` directory with it.

```bash
# on a control node
kubectl hhfab config export > fab.yaml

# on a node with internet access using the exported config
hhfab init -c fab.yaml
```

## Upgrade from Alpha-7 to Beta-1

### Control Node

Ensure the hardware that is to be used for the control node meets the [system requirements](requirements.md#control-node). The upgrade process is destructive of the host, so ensure all data needed is removed from the selected server before the upgrade is started.

### Management Network

Beta-1 uses the RJ-45 management ports of the switches instead of front panel ports. A simple management network will need to be in place and cabled before the install of Beta-1. The control node will run a DHCP server on this network and must be the sole DHCP server. Do not co-mingle other services or equipment on this network, it is for the exclusive use of the control node and switches.

### Install Switch Vendor ONIE

Beta-1 uses the switch vendor ONIE for installation of the NOS. The latest vendor provided version of ONIE is recommended to be installed. Hedgehog ONIE **must not** be used.

### Changes to the Wiring Diagram

* All API versions changed from `v1alpha2` to `v1beta1`
* `Server[control=true]` object type was removed and replaced with `ControlNode` object in the `fabricator.githedgehog.com/v1beta1` API (.spec.control field removed), `Server` object only describes workload server now
* All initial configuration is mainly still available using the `hhfab init` flags but now configurable in the `fab.yaml` file it creates and available in the runtime in the `Fabricator` object in the `fabricator.githedgehog.com/v1beta1` API
* `Connection[type=management]` object removed, relevant information is now present on the `ControlNode` object in the form of the management interface and its config, switches are always connected using management port
* `.spec.location` remove from `Switch` object
* `.spec.boot` added to `Switch` object with `mac` and `serial` fields, at least **one** of them is required to identify switch for installation

### Install The Control Node
Follow the [instructions](install.md#build-control-node-configuration-and-installer) for installing the Beta-1 Fabric on a control node.

### Install NOS using ONIE NOS Install Option
As the switches boot up, select the ONIE option from the grub screen. From there select the "NOS Install" option. The install option will cause the switch to begin searching for installation media, this media is supplied by the control node.
