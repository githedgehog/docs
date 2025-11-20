# External Peering

Hedgehog Fabric uses the Border Leaf concept to exchange VPC routes outside the Fabric and provide L3 connectivity. The
`External Peering` feature allows you to set up an external peering endpoint and to enforce several policies between
internal and external endpoints.

!!! note
    Hedgehog Fabric does not operate Edge side devices.

## Overview

Traffic exits from the Fabric on Border Leaves that are connected with Edge devices. Border Leaves are suitable
to terminate L2VPN connections, to distinguish VPC L3 routable traffic towards Edge devices, and to land VPC servers.
Border Leaves (or Borders) can connect to several Edge devices.

!!! note
    External Peering is only available on the switch devices that are capable for sub-interfaces.

### Connect Border Leaf to Edge device

In order to distinguish VPC traffic, an Edge device should be able to:


- Set up BGP IPv4 to advertise and receive routes from the Fabric
- Connect to a Fabric Border Leaf over VLAN
- Be able to mark egress routes towards the Fabric with BGP Communities
- Be able to filter ingress routes from the Fabric by BGP Communities

All other filtering and processing of L3 Routed Fabric traffic should be done on the Edge devices.

### Control Plane

The Fabric shares VPC routes with Edge devices via BGP. Peering is done over VLAN in IPv4 Unicast AFI/SAFI.

### Data Plane

VPC L3 routable traffic will be tagged with VLAN and sent to Edge device. Later processing of VPC traffic
(NAT, PBR, etc) should happen on Edge devices.

### VPC access to Edge device

Each VPC within the Fabric can be allowed to access Edge devices. Additional filtering can be applied to the routes that
the VPC can export to Edge devices and import from the Edge devices.

## API and implementation

### External

General configuration starts with the specification of `External` objects. Each object of `External` type can represent
a set of Edge devices, or a single BGP instance on Edge device, or any other united Edge entities that can be described
with the following configuration:

- Name of `External`
- Inbound routes marked with the dedicated BGP community
- Outbound routes marked with the dedicated community

Each `External` should be bound to some VPC IP Namespace, otherwise prefixes overlap may happen.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: default--5835
spec:
  ipv4Namespace: # VPC IP Namespace
  inboundCommunity: # BGP Standard Community of routes from Edge devices
  outboundCommunity: # BGP Standard Community required to be assigned on prefixes advertised from Fabric
```

### Connection

A `Connection` of type `external` is used to identify the switch port on Border leaf that is cabled with an Edge device.

```yaml
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: # specified or generated
spec:
  external:
    link:
      switch:
        port: ds3000/E1/1
```

### External Attachment

`External Attachment` defines BGP Peering and traffic connectivity between a Border leaf and `External`. Attachments are
bound to a `Connection` with type `external` and they specify an optional `vlan` that will be used to segregate
particular Edge peering.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: #
spec:
  connection: # Name of the Connection with type external
  external: # Name of the External to pick config
  neighbor:
    asn: # Edge device ASN
    ip: # IP address of Edge device to peer with
  switch:
    ip: # IP address on the Border Leaf to set up BGP peering
    vlan: # VLAN (optional) ID to tag control and data traffic, use 0 for untagged
```

Several `External Attachment` can be configured for the same `Connection` but for different `vlan`.

### External VPC Peering

To allow a specific VPC to have access to Edge devices, bind the VPC to a specific `External` object. To do so, define
an `External Peering` object.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalPeering
metadata:
  name: # Name of ExternalPeering
spec:
  permit:
    external:
      name: # External Name
      prefixes: # List of prefixes (routes) to be allowed to pick up from External
      - # IPv4 prefix
    vpc:
      name: # VPC Name
      subnets: # List of VPC subnets name to be allowed to have access to External (Edge)
      - # Name of the subnet within VPC

```

`Prefixes` is the list of subnets to permit from the External to the VPC. It matches any prefix length less than or
equal to 32, effectively permitting all prefixes within the specified one. Use `0.0.0.0/0` for any route, including the
default route.

This example allows _any_ IPv4 prefix that came from `External`:

```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - prefix: 0.0.0.0/0 # Any route will be allowed including default route
```

This example allows all prefixes that match the default route, with any prefix length:

```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - prefix: 77.0.0.0/8 # Any route that belongs to the specified prefix is allowed (such as 77.0.0.0/8 or 77.1.2.0/24)
```

## Examples

This example shows how to peer with the `External` object with name `HedgeEdge`, given a Fabric VPC with name `vpc-1` on
the Border Leaf `switchBorder` that has a cable connecting it to an Edge device
on the port `E1/2`. Specifying `vpc-1` is required to receive any prefixes advertised from the `External`.

### Fabric API configuration

#### External

```console
# kubectl fabric external create --name hedgeedge --ipns default --in 65102:5000 --out 5000:65102
```

```yaml
- apiVersion: vpc.githedgehog.com/v1beta1
  kind: External
  metadata:
    creationTimestamp: "2024-11-26T21:24:32Z"
    generation: 1
    labels:
      fabric.githedgehog.com/ipv4ns: default
    name: hedgeedge
    namespace: default
    resourceVersion: "57628"
    uid: a0662988-73d0-45b3-afc0-0d009cd91ebd
  spec:
    inboundCommunity: 65102:5000
    ipv4Namespace: default
    outboundCommunity: 5000:6510
```

#### Connection

Connection should be specified in the `wiring` diagram.

```yaml
###
### switchBorder--external--HedgeEdge
###
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: switchBorder--external--HedgeEdge
spec:
  external:
    link:
      switch:
        port: switchBorder/E1/2
```

#### ExternalAttachment

Specified in `wiring` diagram

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: switchBorder--HedgeEdge
spec:
  connection: switchBorder--external--HedgeEdge
  external: HedgeEdge
  neighbor:
    asn: 65102
    ip: 100.100.0.6
  switch:
    ip: 100.100.0.1/24
    vlan: 100
```

#### ExternalPeering

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalPeering
metadata:
  name: vpc-1--HedgeEdge
spec:
  permit:
    external:
      name: HedgeEdge
      prefixes:
      - prefix: 0.0.0.0/0
    vpc:
      name: vpc-1
      subnets:
      - default
```

### Example Edge side BGP configuration based on SONiC OS

!!! warning
    Hedgehog does not recommend using the following configuration for production. It is only provided as an example of
    Edge Peer configuration.

Interface configuration:

```yaml
interface Ethernet2.100
 encapsulation dot1q vlan-id 100
 description switchBorder--E1/2
 no shutdown
 ip vrf forwarding VrfHedge
 ip address 100.100.0.6/24
```

BGP configuration:

```yaml
!
router bgp 65102 vrf VrfHedge
 log-neighbor-changes
 timers 60 180
 !
 address-family ipv4 unicast
  maximum-paths 64
  maximum-paths ibgp 1
  import vrf VrfPublic
 !
 neighbor 100.100.0.1
  remote-as 65103
  !
  address-family ipv4 unicast
   activate
   route-map HedgeIn in
   route-map HedgeOut out
   send-community both
 !
```

Route Map configuration:

```yaml
route-map HedgeIn permit 10
 match community Hedgehog
!
route-map HedgeOut permit 10
 set community 65102:5000
!

bgp community-list standard HedgeIn permit 5000:65102
```

See [Gateway Peering with NAT for External Connections](gateway.md#gateway-peering-for-external-connections) for an examples on how to connect to external networks using NAT.
