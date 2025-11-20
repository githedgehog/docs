# Upgrade

## Upgrades from Beta-1 onwards

Starting with Beta-1 release and onwards, the upgrade process is more streamlined and fully automated. The control node
is upgraded in place and the agents/switches are upgraded using the control node.

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
