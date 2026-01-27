# External Peering

A Border Leaf can be used to exchange VPC routes with external systems. The `External Peering` feature in Hedgehog Fabric
allows users to set up an external peering endpoint and to enforce policies between internal and external endpoints.
Alternatively, the Hedgehog Gateway can be used to provide connectivity via an L2 endpoint directly connected to a Border Leaf.

!!! note
    Hedgehog Fabric does not operate Edge side devices.

## Overview

Traffic exits from the Fabric on Border Leaves that are connected with Edge devices. Border Leaves are suitable
to terminate L2VPN connections, to distinguish VPC L3 routable traffic towards Edge devices, and to land VPC servers.
Border Leaves (or Borders) can connect to several Edge devices.

!!! note
    External Peering is only available on the switch devices that are capable for sub-interfaces.

Hedgehog Fabric supports two types of Edge devices: BGP-speaking (or L3) externals, and Layer 2 (L2) externals.

### Connect a Border Leaf to an Edge device

To separate VPC traffic, the Edge device is typically connected to a Border Leaf using a VLAN.
Additionally, if using the BGP speaker model for external peering, the Edge device should also be capable of:

- Setting up BGP IPv4 to advertise and receive routes from the Fabric
- Marking egress routes towards the Fabric with BGP Communities
- Filtering ingress routes from the Fabric by BGP Communities

All other filtering and processing of L3 Routed Fabric traffic should be done on the Edge devices.

### Control Plane

For L3 externals, the Hedgehog Fabric shares VPC routes with Edge devices via BGP; peering is done over VLAN in IPv4 Unicast AFI/SAFI.

For L2 externals, the Hedgehog Gateway advertises routes to the prefixes specified in the API, using the Edge device IP as next hop.
Traffic reaching the Edge device will appear to be coming from one of a set of assigned Gateway IPs.

### Data Plane

For L3 externals, VPC L3 routable traffic will be tagged with VLAN at a Border Leaf and sent to the Edge device.
Later processing of VPC traffic (NAT, PBR, etc) should happen on Edge devices.

For L2 externals, traffic will first go through the Gateway, where it will be NATed using one of the assigned IPs.
It will then be forwarded to a Border Leaf, where it will be VLAN tagged and forwarded to the Edge device.

### VPC access to Edge device

Each VPC within the Fabric can be allowed to access Edge devices. Additional filtering can be applied to the routes that
the VPC can export to Edge devices and import from the Edge devices.

## API and implementation

### Connection

A `Connection` of type `external` is used to identify the switch port on Border Leaf that is cabled with an Edge device.

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

A `Connection` object can be used with both BGP-speaking and L2 `Externals`.

### BGP-speaking Externals

General configuration starts with the specification of `External` objects. In this section we will introduce the
BGP-speaking externals and their attachments.

#### BGP-speaking External object

Each object of `External` type can represent a set of Edge devices, or a single BGP instance on Edge device, or
any other united Edge entities that can be described with the following configuration:

- Name of the `External`
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

#### BGP-speaking External Attachment object

An `External Attachment` defines BGP Peering and traffic connectivity between a Border Leaf and `External`. Attachments are
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

#### BGP-speaking External VPC Peering

To allow a specific VPC to have access to BGP-speaking Edge devices, bind the VPC to a specific `External` object.

!!! note
    External VPC Peering is only supported for BGP-speaking externals. For L2 externals, see
    [Gateway Peering for External Connections](gateway.md#gateway-peering-for-external-connections).

To do so, define an `External Peering` object.

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

The following example allows _any_ IPv4 prefix learned from the `External`:

```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - prefix: 0.0.0.0/0 # Any route will be allowed including default route
```

The following example only allows routes in the `77.0.0.0/8` prefix, with any prefix length:

```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - prefix: 77.0.0.0/8 # Any route that belongs to the specified prefix is allowed (such as 77.0.0.0/8 or 77.1.2.0/24)
```

### L2 Externals

L2 externals are helpful when the Edge device expects a direct layer-2 connection to the Fabric, as opposed to the BGP-speaking
case we described so far. As far as the Edge device is concerned, traffic from the Fabric should come from a directly connected
device or set of devices, for which the Edge device operator provides IP addresses using our APIs. Prefixes advertised by the
Edge device can be then exposed to VPCs in the Fabric using the Hedgehog Gateway.

#### L2 External object

An L2 `External` uses the same base CRD of the BGP-speaking case, but it does away with
BGP communities. However, the `External` should provide a list of prefixes that are reachable
via itself: since there is no routing protocol involved here, these prefixes have to be advertised
manually via the API.

Like its BGP-speaking counterpart, an L2 `External` should be bound to an IPv4 namespace to avoid prefix overlap.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: ###
spec:
  ipv4Namespace: # VPC IP Namespace
  l2:
    prefixes:
      - # one or more prefixes that are reachable via the Edge device
```

#### L2 External Attachment object

The same `External Attachment` object we saw previously is used for L2 externals; like for `Externals`, some of the fields specific
to BGP-speaking attachments will be left empty, and additional L2-specific configuration is required. Specifically, we require:
- the IP address to be used as next hop for traffic destined to the Edge device;
- an optional VLAN to segregate traffic on the external connection, use `0` for untagged;
- a list of IP addresses that the Edge device is prepared to accept as source-address of incoming traffic from the Fabric;
- an IP address to be configured on the Border Leaf interface connected to the Edge device. This does not have to be in the
  same subnet as the Edge device or Gateway IPs, in fact it can be any IP address that does not collide with the used addressing.
  Its only purpose is to allow the enabling of proxy-ARP on the Border Leaf for that particular interface.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: ###
spec:
  connection: # Name of the Connection with type external
  external: # Name of the External this attachment refers to
  l2:
    ip: # IP address of the Edge device port connected to the Border Leaf
    vlan: # VLAN (optional) ID to tag control and data traffic, use 0 for untagged
    gatewayIPs:
    - # One or more IPs (with prefix length) that can be used in Fabric as source address of traffic directed to the Edge device
    fabricEdgeIP: # IP address (with prefix length) to configure on the port connecting to the Edge device
```

#### L2 External VPC Peering

To peer VPCs to an L2 external, please see [Gateway Peering for External Connections](gateway.md#gateway-peering-for-external-connections).
NAT - either stateful or stateless - should be used so that traffic reaching the Edge device has a source address in the allowed range.

## Examples

This example shows how to peer with the BGP-speaking `External` object with name `HedgeEdge`, given a Fabric VPC with name `vpc-1` on
the Border Leaf `switchBorder` that has a cable connecting it to an Edge device
on the port `E1/2`. Specifying `vpc-1` is required to receive any prefixes advertised from the `External`.

### Fabric API configuration

#### BGP-speaking External

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

#### BGP-speaking ExternalAttachment

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
