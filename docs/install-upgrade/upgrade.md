# Upgrade

## Upgrades removing loopback connections
With Fabric 25.03 and Broadcom SONiC 4.5.0 loopback connections are no longer
required for local VPC peering. A feature flag has been created to assist in a
smooth removal process, `loopbackWorkaroundDisable`, which takes a boolean
value.

### Fresh installs of 25.03

Users in a greenfield environment installing version 25.03 of the Fabric will
see that `hhfab init` will supply the needed option. For users who are
generating configuration in another way ensure that
`loopbackWorkaroundDisable: true` is inside `.spec.config.fabric` of the
Fabricator object.


### Upgrades to 25.03

For users upgrading to version 25.03 follow the steps:

0. Upgrade to 25.03 using steps from previous versions

0. Ensure all switch agents are on v0.80.0 (or greater)
    * `kubectl get agents` to see the version

0. Upgrade the switch operating systems to 4.5.0
    * the switch reinstall feature of k9s is very useful for this purpose

0. Confirm all the switches are up and running SONiC 4.5.0
    * `kubectl get agents -o wide`, look at the Software column

0. Run the command to patch the fabricator object 
    * `kubectl patch -n fab --type merge fabricator/default -p '{"spec":{"config":{"fabric":{"loopbackWorkaroundDisable":true}}}}'`

0. Ensure that all agents have converged:
    * `kubectl get agents -o wide`, ensure that columns currentg == appliedg

0. Now the loopback connections are able to be removed, logically then
   physically
    * `kubectl get connections | grep loopback`
    * `kubectl delete connections/leaf-03--vpc-loopback`
0. Unplug cables as needed


### Beyond 25.03
Starting in 25.04 the presence of `loopbackWorkaroundDisable: true` will be required
in order for updates to take place.


## Upgrades from Beta-1 onwards

Starting with Beta-1 release and onwards, the upgrade process is more streamlined and fully automated. The control node
is upgraded in place and the agents/switches is upgraded using the control node.

In order to apply the upgrade, use the following instructions:

1. Generate the current configuration of your fabric:
    1. On a control node: `kubectl hhfab config export > fab.yaml`
1. On the node with the new version of `hhfab`:
    1. `hhfab init -c fab.yaml -f`, using the fab.yaml from the previous step
    1. run `hhfab build --mode=manual` to generate fully self-contained
       (airgap) upgrade package; for a control node named `control-1`, it will
       be `result/control--control-1--install.tgz`
1. upload it to the control node (e.g. using `scp`)
1. unpack and run `hhfab-recipe upgrade` from the resulting directory

```bash
tar xzf control--control-1--install.tgz
cd control--control-1--install
sudo ./hhfab-recipe upgrade
```

The upgrade will do all necessary steps to upgrade the control node and the
agents/switches. The upgrade process will prompt the user to **reboot**, as part of
upgrading Flatcar on the control node. To validate that the version has been deployed,
run `kubectl -n fab get fab/default -o=jsonpath='{.status.versions.fabricator.controller}'`
and compare to the fabricator version in the release notes.

Upgrade process is idempotent and can be run multiple times without any issues.

Check the [release notes](../release-notes/index.md) for your version to see if a [SONiC
Upgrade](#upgrade-sonic) is available.

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

## Install SONiC using ONIE 

As the switches boot up, select the `ONIE` option from the grub screen. From
there select the `ONIE: Install OS` option. In the grub boot menu the asterisk
(`*`) character functions as an indicator of the option that would be executed
if the `enter` key was pressed. For example to enter the `ONIE` menu it would
appear as `*ONIE` on the screen. The install option will cause the switch to 
begin searching for installation media, this media is supplied by the control node.

## Upgrade SONiC

Occasionally some fabric upgrades will include upgrades to the SONiC Network
Operating System. Upgrading SONiC will cause the switch to not pass traffic
during the upgrade process. For that reason, SONiC is not upgraded
automatically and the user is encouraged to schedule a maintenance window for
the upgrade. 

To upgrade a switch on an existing deployment use the command `kubectl fabric
switch reinstall --name switch-name`. The switch will be gracefully shutdown,
and reboot into the `ONIE` boot environment for reinstallation. After the
switch boots the hedgehog agent will automatically restore the configuration
and traffic will resume without user intervention. 
