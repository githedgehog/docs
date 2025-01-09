# Fabric Shrink/Expand

This section provides a brief overview of how to add or remove switches within the fabric using Hedgehog Fabric API, and
how to manage connections between them.

Manipulating API objects is done with the assumption that target devices are correctly cabled and connected.

This article uses terms that can be found in the [Hedgehog Concepts](../concepts/overview.md), the [User
Guide](overview.md) documentation, and the [Fabric API](../reference/api.md) reference.

### Add a switch to the existing fabric

In order to be added to the Hedgehog Fabric, a switch should have a corresponding `Switch` object. An example on how to define
this object is available in the [User Guide](devices.md).

!!! note
    If the`Switch` will be used in `ESLAG` or `MCLAG` groups, appropriate groups should exist. Redundancy groups should
    be specified in the `Switch` object before creation.

After the `Switch` object has been created, you can define and create dedicated device `Connections`. The types of the
connections may differ based on the `Switch` role given to the device. For more details, refer to [Connections
section](connections.md).

!!! note
    Switch devices need to be booted in `ONIE` installation mode to install SONiC OS and configure the Fabric
    Agent.

Ensure the management port of the switch is connected to fabric management network.

### Remove a switch from the existing fabric

Before you decommission a switch from the Hedgehog Fabric, several preliminary steps are necessary.

* If the `Switch` is a `Leaf` switch (including `Mixed` and `Border` leaf configurations), remove all `VPCAttachments` bound to all switches `Connections`.
* If the `Switch` was used for `ExternalPeering`, remove all `ExternalAttachment` objects that are bound to the `Connections` of the `Switch`.
* Remove all connections of the `Switch`.
* At last, remove the `Switch` and `Agent` objects.

### Replace a switch from the existing fabric

To replace a switch in the fabric, you do not need to remove and re-add it. Instead:

* Edit the existing switch object to update the `MAC` address or `Serial` number of the new hardware.
* Reinstall the switch, following the boot `ONIE` process used when it was first added to the fabric.
