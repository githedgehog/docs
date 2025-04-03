# Fabric Shrink/Expand

This section provides a brief overview of how to add or remove switches within the fabric using Hedgehog Fabric API, and
how to manage connections between them.

Manipulating API objects is done with the assumption that target devices are correctly cabled and connected.

This article uses terms that can be found in the [Hedgehog Concepts](../concepts/overview.md), the [User
Guide](overview.md) documentation, and the [Fabric API](../reference/api.md) reference.

### Add a switch to the existing fabric

In order to be added to the Hedgehog Fabric, a switch should have a corresponding `Switch` object. An example on how to define
this object is available in the [User Guide](devices.md). If the switch is
being added to an existing fabric the user needs to supply the ASN, and IPv4
address for the switch. For a leaf switch, increment the largest ASN by one. If
a spine is being added, it shares the same ASN as the existing spines. For an
IPv4 address increment the largest IP by one, keep the same netmask.

!!! note
    If the`Switch` will be used in `ESLAG` or `MCLAG` groups, appropriate groups should exist. Redundancy groups should
    be specified in the `Switch` object before creation.

#### Expanding Example

A good place to start expanding the fabric is to extract the YAML configuration
for a switch in the role (spine or leaf) that matches the switch to be added.
A good starting point is to take the highest numbered or most recently added
switch of the matching role and increment the IP addresses and numbers by 1.

1. on a control node: `kubectl get switch/leaf-05 -o yaml > new_switch.yaml`
1. Edit new resulting YAML file

``` {yaml annotate title='new_switch.yaml' linenums='1'}
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  creationTimestamp: "2025-04-03T20:44:26Z"
  generation: 1
  labels:
    fabric.githedgehog.com/profile: vs
    vlanns.fabric.githedgehog.com/default: "true"
  name: leaf-05
  namespace: default
  resourceVersion: "3557"
  uid: 04de1762-3c51-4a2d-a9ce-5882494a81c3
spec:
  asn: 65104
  boot:
    mac: 0c:20:12:ff:04:00
  description: VS-05
  ip: 172.30.0.12/21
  profile: vs
  protocolIP: 172.30.8.6/32
  redundancy: {}
  role: server-leaf
  vlanNamespaces:
  - default
  vtepIP: 172.30.12.3/32
```
1. The file contains extra information as the switch is currently deployed. To add a new switch remove the unneeded information.
``` {yaml annotate title='new_switch.yaml' linenums='1'}
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-05 # CHANGE ME
  namespace: default
spec:
  asn: 65104 # CHANGE ME
  boot:
    mac: 0c:20:12:ff:04:00 # CHANGE ME
  description:  row 5, rack c, u 25 # CHANGE ME
  ip: 172.30.0.12/21 # INCREMENT / CHANGE ME
  profile: ds4000 # MATCH TO YOUR NEEDS
  protocolIP: 172.30.8.6/32 # INCREMENT / CHANGE ME
  redundancy: {} # MATCH TO YOUR NEEDS
  role: server-leaf # MATCH TO YOUR NEEDS
  vtepIP: 172.30.12.4/32 # INCREMENT / CHANGE ME
```
1. On the control node: `kubectl apply -f new_switch.yaml`

  * The file can be used to remove the new switch, `kubectl delete -f new_switch.yaml` if needed

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
