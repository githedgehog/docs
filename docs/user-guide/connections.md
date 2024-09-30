# Connections

`Connection` objects represent logical and physical connections between the devices in the Fabric (`Switch`,
`Server` and `External` objects) and are needed to define all the connections in the Wiring Diagram.

All connections reference switch or server ports. Only port names defined by switch profiles can be used in
the wiring diagram for the switches. NOS (or any other) port names aren't supported. Currently, server ports aren't validated by
the Fabric API other than for uniqueness. See the [Switch Profiles and Port Naming](../user-guide/profiles.md) section
for more details.

There are several types of connections.

## Workload server connections

Server connections are used to connect workload servers to switches.

### Unbundled

Unbundled server connections are used to connect servers to a single switch using a single port.

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

Bundled server connections are used to connect servers to a single switch using multiple ports (port channel, LAG).

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

MCLAG server connections are used to connect servers to a pair of switches using multiple ports (Dual-homing).
Switches should be configured as an MCLAG pair which requires them to be in a single redundancy group of type `mclag`
and a Connection with type `mclag-domain` between them. MCLAG switches should also have the same `spec.ASN` and
`spec.VTEPIP`.

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

### ESLAG

ESLAG server connections are used to connect servers to the 2-4 switches using multiple ports (Multi-homing). Switches
should belong to the same redundancy group with type `eslag`, but contrary to the MCLAG case, no other configuration is
required.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: server-1--eslag--s5248-01--s5248-02
  namespace: default
spec:
  eslag:
    links: # Defines multiple links between a single server and a 2-4 switches
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

A Fabric Connection is used between a specific pair of spine and leaf switches, representing all of the wires between them.

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

MCLAG-Domain connections define a pair of MCLAG switches with Session and Peer link between them. Switches should be
configured as an MCLAG, pair which requires them to be in a single redundancy group of type `mclag` and Connection with
type `mclag-domain` between them. MCLAG switches should also have the same `spec.ASN` and `spec.VTEPIP`.

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

VPC-Loopback connections are required in order to implement a workaround for the local VPC peering (when both VPC are
attached to the same switch), which is caused by a hardware limitation of the currently supported switches.

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

Management connections define connections to the Control Node.

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

## Connecting Fabric to the outside world

Connections in this section provide connectivity to the outside world. For example, they can be connections to the
Internet, to other networks, or to some other systems such as DHCP, NTP, LMA, or AAA services.

### StaticExternal

`StaticExternal` connections provide a simple way to connect things like DHCP servers directly to the Fabric by connecting
them to specific switch ports.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: third-party-dhcp-server--static-external--s5248-04
  namespace: default
spec:
  staticExternal:
    link:
      switch:
        port: s5248-04/Ethernet1 # Switch port to use
        ip: 172.30.50.5/24 # IP address that will be assigned to the switch port
        vlan: 1005 # Optional VLAN ID to use for the switch port; if 0, no VLAN is configured
        subnets: # List of subnets to route to the switch port using static routes and next hop
          - 10.99.0.1/24
          - 10.199.0.100/32
        nextHop: 172.30.50.1 # Next hop IP address to use when configuring static routes for the "subnets" list
```

Additionally, it's possible to configure `StaticExternal` within the VPC to provide access to the third-party resources
within a specific VPC, with the rest of the YAML configuration remaining unchanged.

```yaml
...
spec:
  staticExternal:
    withinVPC: vpc-1 # VPC name to attach the static external to
    link:
      ...
```

### External

Connection to external systems, such as edge/provider routers using BGP peering and configuring Inbound/Outbound
communities as well as granularly controlling what gets advertised and which routes are accepted.

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
