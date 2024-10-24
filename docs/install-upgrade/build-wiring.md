# Build Wiring Diagram

!!! warning ""
    Under construction.

## Overview

A wiring diagram is a YAML file that is a digital representation of your network. You can find more YAML level details in the User Guide section [switch features and port naming](../user-guide/profiles.md) and the [api](../reference/api.md). It's mandatory for all switches to reference a `SwitchProfile` in the `spec.profile` of the `Switch` object. Only port naming defined by switch profiles could be used in the wiring diagram, NOS (or any other) port names aren't supported.

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

### Sample Switch Configuration
```yaml
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: ds3000-02
spec:
  boot:
    serial: ABC123XYZ
  role: server-leaf
  description: leaf-2
  profile: celestica-ds3000
  portBreakouts:
    E1/1: 4x10G
    E1/2: 4x10G
    E1/17: 4x25G
    E1/18: 4x25G
    E1/32: 4x25G
  redundancy:
    group: mclag-1
    type: mclag
```

## Design Discussion
This section is meant to help the reader understand how to assemble the primitives presented by the Fabric API into a functional fabric.

### VPC

A VPC allows for isolation at layer 3. This is the main building block for users when creating their architecture. Hosts inside of a VPC belong to the same broadcast domain and can communicate with each other, if desired a single VPC can be configured with multiple broadcast domains. The hosts inside of a VPC will likely need to connect to other VPCs or the outside world. To communicate between two VPC a *peering* will need to be created. A VPC can be a logical separation of workloads. By separating these workloads additional controls are available. The logical separation doesn't have to be the traditional database, web, and compute layers it could be development teams who need isolation, it could be tenants inside of an office building, or any separation that allows for better control of the network. Once your VPCs are decided, the rest of the fabric will come together. With the VPCs decided traffic can be prioritized, security can be put into place, and the wiring can begin. The fabric allows for the VPC to span more than a than one switch, which provides great flexibility, for instance workload mobility.

### Connection

A connection represents the physical wires in your data center. They connect switches to other switches or switches to servers.

#### Server Connections

A server connection is a connection used to connect servers to the fabric. The fabric will configure the server-facing port according to the type of the connection (MLAG, Bundle, etc).The configuration of the actual server needs to be done by the server administrator. The server name is not validated by the fabric and is used as metadata to identify the connection. A server connection can be one of: 

- *Unbundled* - A single cable connecting switch to server.
- *Bundled* - Two or more cables going to a single switch, a LAG or similar.
- *MCLAG* -  Two cables going to two different switches, also called dual homing. The switches will need a fabric link between them.
- *ESLAG* - Two to four cables going to different switches, also called multi-homing. If four links are used there will need to be four switches connected to a single server with four NIC ports.

#### Fabric Connections

Fabric connections serve as connections between switches, they form the fabric of the network.


### VPC Peering

VPCs need VPC Peerings to talk to each other. VPC Peerings come in two varieties: local and remote.

#### Local VPC Peering

When there is no dedicated border/peering switch available in the fabric we can use local VPC peering. This kind of peering tries sends traffic between the two VPC's on the switch where either of the VPC's has workloads attached. Due to limitation in the Sonic network operating system this kind of peering bandwidth is limited to the number of VPC loopbacks you have selected while initializing the fabric. Traffic between the VPCs will use the loopback interface, the bandwidth of this connection will be equal to the bandwidth of port used in the loopback.

#### Remote VPC Peering

Remote Peering is used when you need a high bandwidth connection between the VPCs, you will dedicate a switch to the peering traffic. This is either done on the border leaf or on a switch where either of the VPC's are not present. This kind of peering allows peer traffic between different VPC's at line rate and is only limited by fabric bandwidth. Remote peering introduces a few additional hops in the traffic and may cause a small increase in latency.


#### VPC Loopback

A VPC loopback is a physical cable with both ends plugged into the same switch, suggested but not required to be the adjacent ports. This loopback allows two different VPCs to communicate with each other. This is due to a Broadcom limitation.

