<!--@@joggrdoc@@-->
<!-- @joggr:version(v1):end -->
<!-- @joggr:warning:start -->
<!-- 
  _   _   _    __        __     _      ____    _   _   ___   _   _    ____     _   _   _ 
 | | | | | |   \ \      / /    / \    |  _ \  | \ | | |_ _| | \ | |  / ___|   | | | | | |
 | | | | | |    \ \ /\ / /    / _ \   | |_) | |  \| |  | |  |  \| | | |  _    | | | | | |
 |_| |_| |_|     \ V  V /    / ___ \  |  _ <  | |\  |  | |  | |\  | | |_| |   |_| |_| |_|
 (_) (_) (_)      \_/\_/    /_/   \_\ |_| \_\ |_| \_| |___| |_| \_|  \____|   (_) (_) (_)
                                                              
This document is managed by Joggr. Editing this document could break Joggr's core features, i.e. our 
ability to auto-maintain this document. Please use the Joggr editor to edit this document 
(link at bottom of the page).
-->
<!-- @joggr:warning:end -->
# Connections

The `Connection` object represents a logical and physical connections between any devices in the Fabric (`Switch`,
`Server` and `External` objects). It's needed to define all connections between the devices in the Wiring Diagram.

There are multiple types of connections.

## Server connections (user-facing)

Server connections are used to connect workload servers to the switches.

### Unbundled

Unbundled server connections are used to connect servers to the single switche using a single port.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: server-4--unbundled--s5248-02
  namespace: default
spec:
  unbundled:
    link: # Defines a single link between a server and a switch
      server:
        port: server-4/enp2s1
      switch:
        port: s5248-02/Ethernet3
```

### Bundled

Bundled server connections are used to connect servers to the single switch using multiple ports (port channel, LAG).

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: server-3--bundled--s5248-01
  namespace: default
spec:
  bundled:
    links: # Defines multiple links between a single server and a single switch
    - server:
        port: server-3/enp2s1
      switch:
        port: s5248-01/Ethernet3
    - server:
        port: server-3/enp2s2
      switch:
        port: s5248-01/Ethernet4
```

### MCLAG

MCLAG server connections are used to connect servers to the pair of switches using multiple ports (Dual-homing).

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: server-1--mclag--s5248-01--s5248-02
  namespace: default
spec:
  mclag:
    links: # Defines multiple links between a single server and a pair of switches
    - server:
        port: server-1/enp2s1
      switch:
        port: s5248-01/Ethernet1
    - server:
        port: server-1/enp2s2
      switch:
        port: s5248-02/Ethernet1
```

## Switch connections (fabric-facing)

Switch connections are used to connect switches to each other and provide any needed "service" connectivity to implement
the Fabric features.

### Fabric

Connections between specific spine and leaf, covers all actual wires between a single pair.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: s5232-01--fabric--s5248-01
  namespace: default
spec:
  fabric:
    links: # Defines multiple links between a spine-leaf pair of switches with IP addresses
    - leaf:
        ip: 172.30.30.1/31
        port: s5248-01/Ethernet48
      spine:
        ip: 172.30.30.0/31
        port: s5232-01/Ethernet0
    - leaf:
        ip: 172.30.30.3/31
        port: s5248-01/Ethernet56
      spine:
        ip: 172.30.30.2/31
        port: s5232-01/Ethernet4
```

### MCLAG-Domain

Used to define a pair of MCLAG switches with Session and Peer link between them.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: s5248-01--mclag-domain--s5248-02
  namespace: default
spec:
  mclagDomain:
    peerLinks: # Defines multiple links between a pair of MCLAG switches for Peer link
    - switch1:
        port: s5248-01/Ethernet72
      switch2:
        port: s5248-02/Ethernet72
    - switch1:
        port: s5248-01/Ethernet73
      switch2:
        port: s5248-02/Ethernet73
    sessionLinks: # Defines multiple links between a pair of MCLAG switches for Session link
    - switch1:
        port: s5248-01/Ethernet74
      switch2:
        port: s5248-02/Ethernet74
    - switch1:
        port: s5248-01/Ethernet75
      switch2:
        port: s5248-02/Ethernet75
```

### VPC-Loopback

Required to implement a workaround for the local VPC peering (when both VPC are attached to the same switch) which is
caused by the hardware limitation of the currently supported switches.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: s5248-01--vpc-loopback
  namespace: default
spec:
  vpcLoopback:
    links: # Defines multiple loopbacks on a single switch
    - switch1:
        port: s5248-01/Ethernet16
      switch2:
        port: s5248-01/Ethernet17
    - switch1:
        port: s5248-01/Ethernet18
      switch2:
        port: s5248-01/Ethernet19
```

## Management

Connection to the Control Node.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: control-1--mgmt--s5248-01-front
  namespace: default
spec:
  management:
    link: # Defines a single link between a control node and a switch
      server:
        ip: 172.30.20.0/31
        port: control-1/enp2s1
      switch:
        ip: 172.30.20.1/31
        port: s5248-01/Ethernet0
```

## External

Connection to the external systems, e.g. edge/provider routers.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: s5248-03--external--5835
  namespace: default
spec:
  external:
    link: # Defines a single link between a switch and an external system
      switch:
        port: s5248-03/Ethernet3
```
<!-- @joggr:editLink(82d32cc1-eea9-426f-844d-ce2556058213):start -->
---
<a href="https://app.joggr.io/app/documents/82d32cc1-eea9-426f-844d-ce2556058213/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(82d32cc1-eea9-426f-844d-ce2556058213):end -->