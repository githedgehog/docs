# Build Wiring Diagram

!!! warning ""
    Under construction.

## Overview

A wiring diagram is a yaml file that is a digital representation of your network. You can find more yaml level details in the User Guide section [switch features and port naming](../user-guide/profiles.md) and the [api](../reference/api.md). It's mandatory to for all switches to reference a `SwitchProfile` in the `spec.profile` of the `Switch` object. Only port naming defined by switch profiles could be used in the wiring diagram, NOS (or any other) port names aren't supported.

In the meantime, to have a look at working wiring diagram for Hedgehog Fabric, run the sample generator that produces
VLAB-compatible wiring diagrams:

```console
ubuntu@sl-dev:~$ hhfab sample -h

NAME:
   hhfab sample - generate sample wiring diagram

USAGE:
   hhfab sample command [command options]

COMMANDS:
   spine-leaf, sl      generate sample spine-leaf wiring diagram
   collapsed-core, cc  generate sample collapsed-core wiring diagram
   help, h             Shows a list of commands or help for one command

OPTIONS:
   --help, -h  show help
```

## Design Discussion
This section is meant to help the reader understand how to assemble the primitives presented by the Fabric API into a functional fabric.

### VPC

A VPC allows for isolation at layer 3. This is the main building block for users when creating their architecture. Hosts inside of a VPC will see each other but nothing else. The hosts inside of a VPC will likely need to connect to other VPCs or the outside world. To communicate between two VPC a *peering* will need to be created. A VPC can be a logical separation of workloads. By separating these workloads additional controls are available. The logical separation doesn't have to be the traditional database, web, and compute layers it could be development teams who need isolation, it could tenants inside of an office building, or any separation that allows for better control of the network. Once your VPCs are decided, the rest of the fabric will come together. With the VPCs decided traffic can be prioritized, security can be put into place, and the wiring can begin. The fabric allows for the VPC to exist beyond a single switch, which gives flexibility when the physical world meets the digital.

### Connection

A connection represents the physical wires in your data center. They connect switches to other switches or switches to servers.

#### Server Connections

A server connection will require server side configuration as the Fabric configuration abilities do not reach into the end hosts. A server connection can be one of: 

- *Unbundled* - a single cable going from switch to server
- *Bundled* - two or more cables going to a single switch, the server needs to configured for this, Fabric handles the switch
- *MCLAG* -  two cables going to two different switches, also called dual homing. The switches will need a fabric link between them
- *ESLAG* - two to four cables going to different switches, also called multi-homing. If four links are used there will be four switches connected to a single server with four NIC ports

#### Fabric Connections

These serve as connection between switches, their beautiful weave comprises the fabric of the network.


### VPC Peering

This is what is needed for VPCs to talk to each other. There are two varieties local and remote.

#### Local VPC Peering

When the VPCs that need to communicate are both on the same switch. An example would be if your database and web front end servers are in the same rack and are able to be physically cabled to the same switch.

#### Remote VPC Peering

When the VPCs that need to communicate are on different switches. An example would be if your storage and compute servers are in opposite ends of the data center and need to be cabled to different switches.



## Design Examples

### TODO - show the wiring diagram for a leaf-spine

### TODO - show how to connect to an AWS cloud connection

### TODO - show how to connect to a provider ISP like equinix
