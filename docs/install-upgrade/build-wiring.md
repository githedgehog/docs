# Build Wiring Diagram


## Overview

A wiring diagram is a YAML file that is a digital representation of your
network. You can find more YAML level details in the User Guide section [switch
features and port naming](../user-guide/profiles.md) and the
[api](../reference/fabric-api.md). It's mandatory for all switches to reference a
`SwitchProfile` in the `spec.profile` of the `Switch` object. Only port naming
defined by switch profiles could be used in the wiring diagram, NOS (or any
other) port names aren't supported. An complete example wiring diagram is
[below](build-wiring.md#sample-wiring-diagram).

A good place to start building a wiring diagram is with the switch profiles.
Start with the switches, then move onto the fabric links, and finally the
server connections.

### Sample Switch Configuration
``` { .yaml .annotate linenums="1" }
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: ds3000-02
spec:
  boot: # Serial or MAC can be used
    serial: ABC123XYZ
    mac: 34:AD:61:00:02:03 # Usually the first management port MAC address
  role: server-leaf
  description: rack 5, aisle 3, RU 22
  profile: celestica-ds3000 # (1)!
  portBreakouts: # (2)!
    E1/1: 4x10G
    E1/2: 4x10G
    E1/17: 4x25G
    E1/18: 4x25G
    E1/32: 4x25G
  redundancy: # (3)!
    group: eslag-1
    type: eslag
```

1. See the [list](../reference/profiles.md) of profile names
2. More information in the [User Guide](../user-guide/profiles.md#port-naming)
3. Could be MCLAG, ESLAG or nothing, more details in [Redundancy
   Groups](../user-guide/devices.md#redundancy-groups)

## Design Discussion
This section is meant to help the reader understand how to assemble the primitives presented by the Fabric API into a functional fabric.

### VPC

A VPC allows for isolation at layer 3. This is the main building block for users when creating their architecture. Hosts inside of a VPC belong to the same broadcast domain and can communicate with each other, if desired a single VPC can be configured with multiple broadcast domains. The hosts inside of a VPC will likely need to connect to other VPCs or the outside world. To communicate between two VPC a *peering* will need to be created. A VPC can be a logical separation of workloads. By separating these workloads additional controls are available. The logical separation doesn't have to be the traditional database, web, and compute layers it could be development teams who need isolation, it could be tenants inside of an office building, or any separation that allows for better control of the network. Once your VPCs are decided, the rest of the fabric will come together. With the VPCs decided traffic can be prioritized, security can be put into place, and the wiring can begin. The fabric allows for the VPC to span more than one switch, which provides great flexibility.

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

Fabric connections serve as connections between spine and leaf switches; they form the fabric of the network.

#### Mesh Connections

Mesh connections directly connect leaf switches with each other; they are useful when creating small mesh
topologies without spines.

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

When there is no dedicated border/peering switch available in the fabric we can use local VPC peering. This kind of peering tries to send traffic between the two VPCs on the switch where either of the VPCs has workloads attached.

``` mermaid
graph TD

    L1([Leaf 1])
    S1[Server1]
    S2[Server2]
    S3[Server3]
    S4[Server4]

    L1 <-.2.-> S1;
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
The dotted line in the diagram shows the traffic flow for local peering. The traffic originates in VPC 2, travels to the switch, and finally out the port destined for VPC 1.


#### Remote VPC Peering

Remote Peering is used when you need a high bandwidth connection between the VPCs, you will dedicate a switch to the peering traffic. This is either done on the border leaf or on a switch where either of the VPC's are not present. This kind of peering allows peer traffic between different VPCs at line rate and is only limited by fabric bandwidth. Remote peering introduces a few additional hops in the traffic and may cause a small increase in latency.

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

## Sample Wiring Diagram

The YAML listing below shows a complete wiring diagram for a spine-leaf topology. It illustrates
how switches from a single vendor can be arranged to form a fabric. There are no IP
addresses or ASN numbers in this listing, the `hhfab build` step creates those as part
of creating the fabric. To physically connect this topology, 16 cables are
needed for the fabric links. Additional cables are needed to connect servers into the fabric.

``` {.yaml .annotate linenums="1" title="wiring_diagram.yaml"}
#
# VLANNamespaceList
#
apiVersion: wiring.githedgehog.com/v1beta1
kind: VLANNamespace
metadata:
  name: default
spec:
  ranges:
  - from: 1000
    to: 2999
#
# IPv4NamespaceList
#
---
apiVersion: vpc.githedgehog.com/v1beta1
kind: IPv4Namespace
metadata:
  name: default
spec:
  subnets:
  - 10.0.0.0/16
#
# SwitchGroupList
#
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: SwitchGroup
metadata:
  name: empty
spec: {}
#
# SwitchList
#
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-01
spec:
  boot:
    mac: 0c:20:12:ff:00:00 # CHANGE ME
  description: leaf-01
  profile:  celestica-ds3000
  redundancy: {}
  role: server-leaf
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-02
spec:
  boot:
    mac: 0c:20:12:ff:01:00 # CHANGE ME
  description: leaf-02
  profile: celestica-ds3000
  redundancy: {}
  role: server-leaf
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-03
spec:
  boot:
    mac: 0c:20:12:ff:02:00 # CHANGE ME
  description: leaf-03
  profile: celestica-ds3000
  redundancy: {}
  role: server-leaf
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-04
spec:
  boot:
    mac: 0c:20:12:ff:03:00 # CHANGE ME
  description: leaf-04
  profile: celestica-ds3000
  redundancy: {}
  role: server-leaf
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: spine-01
spec:
  boot:
    mac: 0c:20:12:ff:05:00 # CHANGE ME
  description: spine-01
  profile: celestica-ds4000
  portBreakouts:
    E1/1: 4x100G
    E1/2: 4x100G
  redundancy: {}
  role: spine
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: spine-02
spec:
  boot:
    mac: 0c:20:12:ff:06:00 # CHANGE ME
  description: spine-02
  profile: celestica-ds4000
  portBreakouts:
    E1/1: 4x100G
    E1/2: 4x100G
  redundancy: {}
  role: spine
#
# ConnectionList
#
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-01--fabric--leaf-01
spec:
  fabric:
    links:
    - leaf:
        port: leaf-01/E1/8
      spine:
        port: spine-01/E1/1/1
    - leaf:
        port: leaf-01/E1/9
      spine:
        port: spine-01/E1/2/1
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-01--fabric--leaf-02
spec:
  fabric:
    links:
    - leaf:
        port: leaf-02/E1/9
      spine:
        port: spine-01/E1/1/2
    - leaf:
        port: leaf-02/E1/10
      spine:
        port: spine-01/E1/2/2
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-01--fabric--leaf-03
spec:
  fabric:
    links:
    - leaf:
        port: leaf-03/E1/4
      spine:
        port: spine-01/E1/1/3
    - leaf:
        port: leaf-03/E1/5
      spine:
        port: spine-01/E1/2/3
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-01--fabric--leaf-04
spec:
  fabric:
    links:
    - leaf:
        port: leaf-04/E1/5
      spine:
        port: spine-01/E1/1/4
    - leaf:
        port: leaf-04/E1/6
      spine:
        port: spine-01/E1/2/4
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-02--fabric--leaf-01
spec:
  fabric:
    links:
    - leaf:
        port: leaf-01/E1/10
      spine:
        port: spine-02/E1/1/1
    - leaf:
        port: leaf-01/E1/11
      spine:
        port: spine-02/E1/2/1
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-02--fabric--leaf-02
spec:
  fabric:
    links:
    - leaf:
        port: leaf-02/E1/11
      spine:
        port: spine-02/E1/1/2
    - leaf:
        port: leaf-02/E1/12
      spine:
        port: spine-02/E1/2/2
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-02--fabric--leaf-03
spec:
  fabric:
    links:
    - leaf:
        port: leaf-03/E1/6
      spine:
        port: spine-02/E1/1/3
    - leaf:
        port: leaf-03/E1/7
      spine:
        port: spine-02/E1/2/3
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-02--fabric--leaf-04
spec:
  fabric:
    links:
    - leaf:
        port: leaf-04/E1/7
      spine:
        port: spine-02/E1/1/4
    - leaf:
        port: leaf-04/E1/8
      spine:
        port: spine-02/E1/2/4
```
