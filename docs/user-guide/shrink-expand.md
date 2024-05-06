# Fabric Shrink/Expand

This section provides a brief overview of how to add or remove switches within the fabric using Hedgehog Fabric API, and
how to manage connections between them.

Manipulating API objects is done with the assumption that target devices are correctly cabeled and connected.

This article operates terms that can be found in the [Hedgehog Concepts](../concepts/overview.md), the [User
Guide](overview.md) documentation, and the [Fabric API](../reference/api.md) reference.

### Add a switch to the existing fabric

To be added to the Hedgehog Fabric, a switch should have a corresponding `Switch` object. An example on how to define
this object is available in the [User Guilde](devices.md).

!!! note
    If the`Switch` will be used in `ESLAG` or `MCLAG` groups, appropriate groups should exist. Redundancy groups should
    be specified in the `Switch` object before creation.

After the `Switch` object has been created, you can define and create dedicated device `Connections`. The types of the
connections may differ based on the `Switch` role given to the device. For more details, refer to [Connections
section](connections.md).

!!! note
    If the switch is facing a Control Node Connection on the front-panel port, the switch port should be described in a
    `Management` connection.

!!! note
    Switch devices should be booted in `ONIE` or `HONIE` installation mode to install SONiC OS and configure the Fabric
    Agent.

### Remove a switch from the existing fabric

Before you decommission a switch from the Hedgehog Fabric, several preparation steps are necessary.

!!! warning
    Currently the `Wiring` diagram used for initial deployment is saved in
    `/var/lib/rancher/k3s/server/manifests/hh-wiring.yaml` on the `Control` node. Fabric will sustain objects within the
    original wiring diagram. In order to remove any object, first remove the dedicated API objects from this file. It is
    recommended to reapply `hh-wiring.yaml` after changing its internals.

* If the `Switch` is a `Leaf` switch (including `Mixed` and `Border` leaf configurations), remove all `VPCAttachments` bound to all switches `Connections`.
* If the `Switch` was used for `ExternalPeering`, remove all `ExternalAttachment` objects that are bound to the `Connections` of the `Switch`.
* Remove all connections of the `Switch`.
* At last, remove the `Switch` and `Agent` objects.
