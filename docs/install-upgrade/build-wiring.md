# Build Wiring Diagram

!!! warning ""
    Under construction.

## Overview

A wiring diagram is a YAML file that is a digital representation of your network. You can find more YAML level details in the User Guide section [switch features and port naming](../user-guide/profiles.md) and the [api](../reference/api.md). It's mandatory for all switches to reference a `SwitchProfile` in the `spec.profile` of the `Switch` object. Only port naming defined by switch profiles could be used in the wiring diagram, NOS (or any other) port names aren't supported.

In the meantime, to have a look at working wiring diagram for Hedgehog Fabric, run the sample generator that produces
working wiring diagrams:

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

Or you can generate a wiring diagram for a VLAB environment with flags to customize number of switches, links, servers, etc.:

```console
ubuntu@sl-dev:~$ hhfab vlab gen --help
NAME:
   hhfab vlab generate - generate VLAB wiring diagram

USAGE:
   hhfab vlab generate [command options]

OPTIONS:
   --bundled-servers value      number of bundled servers to generate for switches (only for one of the second switch in the redundancy group or orphan switch) (default: 1)
   --eslag-leaf-groups value    eslag leaf groups (comma separated list of number of ESLAG switches in each group, should be 2-4 per group, e.g. 2,4,2 for 3 groups with 2, 4 and 2 switches)
   --eslag-servers value        number of ESLAG servers to generate for ESLAG switches (default: 2)
   --fabric-links-count value   number of fabric links if fabric mode is spine-leaf (default: 0)
   --help, -h                   show help
   --mclag-leafs-count value    number of mclag leafs (should be even) (default: 0)
   --mclag-peer-links value     number of mclag peer links for each mclag leaf (default: 0)
   --mclag-servers value        number of MCLAG servers to generate for MCLAG switches (default: 2)
   --mclag-session-links value  number of mclag session links for each mclag leaf (default: 0)
   --no-switches                do not generate any switches (default: false)
   --orphan-leafs-count value   number of orphan leafs (default: 0)
   --spines-count value         number of spines if fabric mode is spine-leaf (default: 0)
   --unbundled-servers value    number of unbundled servers to generate for switches (only for one of the first switch in the redundancy group or orphan switch) (default: 1)
   --vpc-loopbacks value        number of vpc loopbacks for each switch (default: 0)
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

``` mermaid
graph TD
    L1([Leaf 1])
    L2([Leaf 2])
    S1["Server 1
      10.7.71.1"]
    S2["Server 2
      172.16.2.31"]
    S3["Server 3
       192.168.18.85"]

    L1 <--> S1
    L1 <--> S2
    L2 <--> S3

    subgraph VPC 1
    S1
    S2
    S3
    end
```
### Connection

A connection represents the physical wires in your data center. They connect switches to other switches or switches to servers.

#### Server Connections

A server connection is a connection used to connect servers to the fabric. The fabric will configure the server-facing port according to the type of the connection (MLAG, Bundle, etc). The configuration of the actual server needs to be done by the server administrator. The server port names are not validated by the fabric and used as metadata to identify the connection. A server connection can be one of:

- *Unbundled* - A single cable connecting switch to server.
- *Bundled* - Two or more cables going to a single switch, a LAG or similar.
- *MCLAG* -  Two cables going to two different switches, also called dual homing. The switches will need a fabric link between them.
- *ESLAG* - Two to four cables going to different switches, also called multi-homing. If four links are used there will need to be four switches connected to a single server with four NIC ports.

``` mermaid
graph TD
    S1([Spine 1])
    S2([Spine 2])
    L1([Leaf 1])
    L2([Leaf 2])
    L3([Leaf 3])
    L4([Leaf 4])
    L5([Leaf 5])
    L6([Leaf 6])
    L7([Leaf 7])

    TS1[Server1]
    TS2[Server2]
    TS3[Server3]
    TS4[Server4]

    S1 & S2 ---- L1 & L2 & L3 & L4 & L5 & L6 & L7
    L1 <-- Bundled --> TS1
    L1 <-- Bundled --> TS1
    L1 <-- Unbundled --> TS2
    L2 <-- MCLAG --> TS3
    L3 <-- MCLAG --> TS3
    L4 <-- ESLAG --> TS4
    L5 <-- ESLAG --> TS4
    L6 <-- ESLAG --> TS4
    L7 <-- ESLAG --> TS4

    subgraph VPC 1
    TS1
    TS2
    TS3
    TS4
    end
    
    subgraph MCLAG
    L2
    L3
    end

    subgraph ESLAG
    L3
    L4
    L5
    L6
    L7
    end
    
```
#### Fabric Connections

Fabric connections serve as connections between switches, they form the fabric of the network.


### VPC Peering

VPCs need VPC Peerings to talk to each other. VPC Peerings come in two varieties: local and remote.

``` mermaid
graph TD
    S1([Spine 1])
    S2([Spine 2])
    L1([Leaf 1])
    L2([Leaf 2])
    TS1[Server1]
    TS2[Server2]
    TS3[Server3]
    TS4[Server4]

    S1 & S2 <--> L1 & L2
    L1 <--> TS1 & TS2
    L2 <--> TS3 & TS4


    subgraph VPC 1
    TS1
    TS2
    end

    subgraph VPC 2
    TS3
    TS4
    end
```

#### Local VPC Peering

When there is no dedicated border/peering switch available in the fabric we can use local VPC peering. This kind of peering tries sends traffic between the two VPC's on the switch where either of the VPC's has workloads attached. Due to limitation in the Sonic network operating system this kind of peering bandwidth is limited to the number of VPC loopbacks you have selected while initializing the fabric. Traffic between the VPCs will use the loopback interface, the bandwidth of this connection will be equal to the bandwidth of port used in the loopback.

``` mermaid
graph TD

    L1([Leaf 1])
    S1[Server1]
    S2[Server2]
    S3[Server3]
    S4[Server4]

    L1 <-.2,loopback.-> L1;
    L1 <-.3.-> S1;
    L1 <--> S2 & S4;
    L1 <-.1.-> S3;

    subgraph VPC 1
    S1
    S2
    end

    subgraph VPC 2
    S3
    S4
    end



```


#### Remote VPC Peering

Remote Peering is used when you need a high bandwidth connection between the VPCs, you will dedicate a switch to the peering traffic. This is either done on the border leaf or on a switch where either of the VPC's are not present. This kind of peering allows peer traffic between different VPC's at line rate and is only limited by fabric bandwidth. Remote peering introduces a few additional hops in the traffic and may cause a small increase in latency.

``` mermaid
graph TD
    S1([Spine 1])
    S2([Spine 2])
    L1([Leaf 1])
    L2([Leaf 2])
    L3([Leaf 3])
    TS1[Server1]
    TS2[Server2]
    TS3[Server3]
    TS4[Server4]

    S1 <-.5.-> L1;
    S1 <-.2.-> L2;
    S1 <-.3,4.-> L3;
    S2 <--> L1;
    S2 <--> L2;
    S2 <--> L3;
    L1 <-.6.-> TS1;
    L1 <--> TS2;
    L2 <--> TS3;
    L2 <-.1.-> TS4;


    subgraph VPC 1
    TS1
    TS2
    end

    subgraph VPC 2
    TS3
    TS4
    end
```
The dotted line in the diagram shows the traffic flow for remote peering. The traffic could take a different path because of ECMP. It is important to note that Leaf 3 cannot have any servers from VPC 1 or VPC 2 on it, but it can have a  different VPC attached to it.

#### VPC Loopback

A VPC loopback is a physical cable with both ends plugged into the same switch, suggested but not required to be the adjacent ports. This loopback allows two different VPCs to communicate with each other. This is due to a Broadcom limitation.

