# Upgrade

## Upgrades from Beta-1 onwards

Starting with Beta-1 release and onwards, the upgrade process is more streamlined and fully automated. The control node
is upgraded in place and the agents/switches are upgraded using the control node.

!!! warning
    Plan for an outage during the upgrade: traffic that goes through the gateways can be
    interrupted while the gateway components restart during the control node upgrade.
    Upgrade the control node first and then the gateway nodes, if your fabric has any.
    When upgrading from 26.04 or older, gateway traffic stays interrupted until each gateway
    node is upgraded and rebooted, see [Upgrade gateway nodes](#upgrade-gateway-nodes).

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

After the upgrade, the new fabric controller initializes before deploying anything, and changes to the Fabric API
objects are refused until it's done. Check that it's `Ready` with `kubectl get fabriccontrollers -A`, see
[Fabric Controller](../troubleshooting/fabric-controller.md) for details.

Check the [release notes](../release-notes/index.md) for your version to see if a [SONiC
Upgrade](#upgrade-sonic) is available.

### Upgrade gateway nodes

If your fabric has gateway nodes, upgrade them after the control node upgrade has finished.
The same `hhfab build --mode=manual` run that generated the control node package also
generates one package per gateway node; for a gateway node named `gateway-1`, it will be
`result/node--gateway-1--install.tgz`.

For each gateway node:

1. upload its package to the gateway node (e.g. using `scp`)
1. unpack and run `hhfab-recipe upgrade` from the resulting directory

```bash
tar xzf node--gateway-1--install.tgz
cd node--gateway-1--install
sudo ./hhfab-recipe upgrade
```

!!! warning
    When upgrading from 26.04 or older, the gateway node needs a reboot to reserve hugepages and enable the IOMMU
    with the kernel arguments. The upgrade sets them and stops with an error asking to reboot the node; reboot it and
    run `sudo ./hhfab-recipe upgrade` again. The gateway node must have IOMMU support (Intel VT-d or AMD-Vi) enabled
    in the firmware, see [System Requirements](requirements.md#gateway-node).

    The gateway dataplane doesn't start until the gateway node is upgraded and rebooted, so traffic that goes through
    the gateways is interrupted from the control node upgrade until then.

After the upgrade, check from the control node that the gateway node is `Ready`:

```console
core@control-1 ~ $ kubectl get nodes
NAME        STATUS   ROLES                AGE    VERSION
control-1   Ready    control-plane,etcd   2d2h   v1.36.4+k3s1
gateway-1   Ready    <none>               2d2h   v1.36.4+k3s1
```

and that its gateway pod, named `gw--<gateway name>-...`, is `Running`:

```console
core@control-1 ~ $ kubectl -n fab get pods
NAME                  READY   STATUS    RESTARTS   AGE
gw--gateway-1-qtp7p   2/2     Running   0          5m
[..]
```

The other pods in the `fab` namespace are listed as well.

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
