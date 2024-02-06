# Switch adding/removing guide 

This article gives brief overview of how to add or remove switches within the fabric using Hedgehog Fabric API and manage connection relations between them.

Manipulating with API objects done with assumption that target devices are correctly cabeled and connected.

This article operates terms that can be found in [Hedgehog Concepts](../concepts/overview.md), [User Guide](overview.md) documentation and [Fabric API](../reference/api.md) reference.

### Add switch to existing fabric

For every switch needs to be installed into the Hedgehog fabric it's should be attached to the fabric dedicated `Switch` object has to be described. Example can be found in [User Guilde](devices.md).

>If the`Switch` will be used in `ESLag` or `MCLag` groups, appropriate groups should exists. Groups should be specified in the `Switch` object before creation.

After the `Switch` object is created for dedicated device `Connections` can be defined and created. Based on the `Switch` role given to the device types of connections may be different. Please refer to [Connections section](connections.md).

>If switch is facing control node connection on the front-pannel port, such switch port should be described in `Management` connection

>Switch device should be booted in `ONIE` or `HONIE` Installation mode to install SONiC OS and configure Fabric agent

### Remove switch from the existing fabric

If the switch has to be decommissioned or removed there are several preparation steps before disabling it from the Fabric.

> [!WARNING]
> Currently the `Wiring` diagram used for initial deployment is saved in `/var/lib/rancher/k3s/server/manifests/hh-wiring.yaml` on the `Control` node. Fabric will sustain objects within the original wiring diagram. In order to remove any of the object that is described in this chapter, dedicated API object should be first removed from this file. It's recommended to reapply `hh-wiring.yaml` after changing it's internals.

- If the `Switch` is a `Leaf` switch (including `Mixed` and `Border` leaf configuration) all `VPCAttachments` bound to all switches `Connections` must be removed first. If the `Switch` was used for `ExternalPeering` all `ExternalAttachment` object that are bound to `Connections` of the `Switch` must be removed.
-  All connections of the `Switch` must be removed.
- `Switch` and `Agent` object can be removed.

