# Upgrading from Alpha-7 to Beta-1
## Control Node
Ensure the hardware that is to be used for the control node meets the [system requirements](requirements.md#control-node). The upgrade process is destructive of the host, so ensure all data needed is removed from the selected server before the upgrade is started.

## Management Network
Beta-1 uses the RJ-45 management ports of the switches instead of front panel ports. A simple management network will need to be in place and cabled before the install of Beta-1. The control node will run a DHCP server on this network and must be the sole DHCP server. Do not co-mingle other services or equipment on this network, it is for the exclusive use of the control node and switches.

## Install Switch Vendor ONIE
Beta-1 uses the switch vendor onie for installation of the NOS. The latest vendor provided version of ONIE is recommended to be installed.


## Changes to the Wiring Diagram

* All API versions changed from `v1alpha2` to `v1beta1`
* `Server[control=true]` object type was removed and replaced with `ControlNode` object in the `fabricator.githedgehog.com/v1beta1` API (.spec.control field removed), `Server` object only describes workload server now
* All initial configuration is mainly still available using the `hhfab init` flags but now configurable in the `fab.yaml` file it creates and available in the runtime in the `Fabricator` object in the `fabricator.githedgehog.com/v1beta1` API
* `Connection[type=management]` object removed, relevant information is now present on the `ControlNode` object in the form of the management interface and its config, switches are always connected using management port
* `.spec.location` remove from `Switch` object
* `.spec.boot` added to `Switch` object with `mac` and `serial` fields, at least **one** of them is required to identify switch for installation

## Install The Control Node
Follow the [instructions](install.md#build-control-node-configuration-and-installer) for installing the Beta-1 Fabric on a control node.


## Install NOS using ONIE NOS Install Option
As the switches boot up, select the ONIE option from the grub screen. From there select the "NOS Install" option. The install option will cause the switch to begin searching for installation media, this media is supplied by the control node.


