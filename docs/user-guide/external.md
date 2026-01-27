# External Peering

A Border Leaf can be used to exchange VPC routes with external systems. The `External Peering` feature in Hedgehog Fabric
allows users to set up an external peering endpoint and to enforce policies between internal and external endpoints.
Alternatively, the Hedgehog Gateway can be used to provide connectivity via an endpoint directly connected to a Border Leaf.

!!! note
    Hedgehog Fabric does not operate Edge side devices.

## Overview

Traffic exits from the Fabric on Border Leaves that are connected to Edge Devices. Border Leaves are suitable
to terminate L2VPN connections, to distinguish VPC L3 routable traffic towards Edge Devices, and to land VPC servers.
Border Leaves (or Borders) can connect to several Edge Devices.

!!! note
    External Peering is only available on switch devices that support sub-interfaces.

Hedgehog Fabric supports both BGP-speaking and static externals.

### Connect a Border Leaf to an Edge Device

To separate VPC traffic, the Edge Device is typically connected to a Border Leaf using a VLAN.
Additionally, if using the BGP speaker model for external peering, the Edge Device should also be capable of:

- Setting up BGP IPv4 to advertise and receive routes from the Fabric
- Marking egress routes towards the Fabric with BGP Communities
- Filtering ingress routes from the Fabric by BGP Communities

All other filtering and processing of L3 Routed Fabric traffic should be done on the Edge Devices.

### Control Plane

For BGP externals, the Hedgehog Fabric shares VPC routes with Edge Devices via BGP; peering is done over VLAN in IPv4 Unicast AFI/SAFI.

For static externals, static routes for the listed prefixes are installed in a VRF associated with the external
in the Border Leaf. These routes can be exposed to VPCs either via route leaking on the Border Leaf itself or
via the Hedgehog Gateway, which adds support for more advanced features such as source NAT. When using the Gateway,
Proxy ARP is configured on the Border Leaf to emulate a direct connection between the external and the Gateway.

### Data Plane

For BGP and non-proxied static externals, VPC L3 routable traffic will be tagged with VLAN at a Border Leaf and sent to the Edge Device.
Later processing of VPC traffic (NAT, PBR, etc) should happen on Edge Devices.

For proxied static externals, traffic will first go through the Gateway, where it will be NATed using one of the assigned IPs.
It will then be forwarded to a Border Leaf, where it will be VLAN tagged and forwarded to the Edge Device.

### VPC access to Edge Device

Each VPC within the Fabric can be allowed to access Edge Devices. Additional filtering can be applied to the routes that
the VPC can export to Edge Devices and import from the Edge Devices.

## API and implementation

### Connection

A `Connection` of type `external` is used to identify the switch port on Border Leaf that is cabled with an Edge Device.

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

A `Connection` object can be used with both BGP-speaking and static `Externals`.

### BGP-speaking Externals

General configuration starts with the specification of `External` objects. In this section we will introduce the
BGP-speaking externals and their attachments.

#### BGP-speaking External object

Each object of `External` type can represent a set of Edge Devices, or a single BGP instance on Edge Device, or
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
  inboundCommunity: # BGP Standard Community of routes from Edge Devices
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
    asn: # Edge Device ASN
    ip: # IP address of Edge Device to peer with
  switch:
    ip: # IP address on the Border Leaf to set up BGP peering
    vlan: # VLAN (optional) ID to tag control and data traffic, use 0 for untagged
```

Several `External Attachment` can be configured for the same `Connection` but for different `vlan`.

### Static Externals

If the Edge Device cannot run BGP and the reachable prefixes are known in advance, static externals can be used instead.
As far as the Edge Device is concerned, traffic from the Fabric should come from a directly connected
device or set of devices on the same subnet as itself.

#### Static External object

A static `External` uses the same base CRD of the BGP-speaking case, but it does away with
BGP communities. However, the `External` should provide a list of prefixes that are reachable
via itself, as there is no routing protocol to dynamically learn them from.

Like its BGP-speaking counterpart, a static `External` should be bound to an IPv4 namespace to avoid prefix overlaps.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: ###
spec:
  ipv4Namespace: # VPC IP Namespace
  static:
    prefixes:
      - # one or more prefixes that are reachable via the Edge Device
```

#### Static External Attachment object

The same `External Attachment` object we saw previously is used for static externals; like for `Externals`, fields specific
to BGP-speaking attachments will be left empty, and some additional configuration is required. Specifically, we need:

- the remote IP address of the external, which is used as next hop for traffic forwarded to the Edge Device;
- an optional VLAN to segregate traffic on the external connection, or `0` for untagged traffic;
- a `proxy` flag, which should be set to `true` if the user intends to peer VPCs with the external using the Hedgehog Gateway;
- the IP address to be configured on the Border Leaf side of the link, when the `proxy` flag is not set; it should be empty otherwise.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: ###
spec:
  connection: # Name of the Connection with type external
  external:   # Name of the External this attachment refers to
  static:
    remoteIP: # IP address of the Edge Device port connected to the Border Leaf
    vlan:     # VLAN (optional) ID to tag control and data traffic, use 0 for untagged
    proxy:    # Flag to enable proxy-ARP, used in conjunction with Gateway peering
    ip:       # IP address (with prefix length) to be configured on the switch when not using Proxy mode, empty otherwise
```

### External VPC Peering

To allow a specific VPC to have access to prefixes reachable via an Edge Device, bind the VPC to the corresponding
`External` by creating an `External Peering` object.

!!! note
    External VPC Peering via this Fabric object is only supported for BGP-speaking externals or
    static externals without proxy ARP. For the proxied static external use case, or whenever NAT
    is required to access the target prefixes, Gateway peering should be used instead: see
    [Gateway Peering for External Connections](gateway.md#gateway-peering-for-external-connections).

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

## Example 1: BGP-speaking external

This example shows how to peer with the BGP-speaking `External` object with name `bgp-edge`, given a Fabric VPC with name `vpc-01` on
the Border Leaf `switch-border` that has a cable connecting it to an Edge Device
on port `E1/2`. Specifying `vpc-01` is required to receive any prefixes advertised from the `External`.

### Fabric API configuration

#### BGP-speaking External

```console
# kubectl fabric external create --name bgp-edge --ipns default --in 65102:5000 --out 5000:65102
```

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: bgp-edge
  namespace: default
spec:
  inboundCommunity: 65102:5000
  ipv4Namespace: default
  outboundCommunity: 5000:65102
```

#### Connection

The connection should be specified in the `wiring` diagram.

```yaml
###
### switch-border--external--bgp-edge
###
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: switch-border--external--bgp-edge
spec:
  external:
    link:
      switch:
        port: switch-border/E1/2
```

#### BGP-speaking ExternalAttachment

Specified in `wiring` diagram

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: switch-border--bgp-edge
spec:
  connection: switch-border--external--bgp-edge
  external: bgp-edge
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
  name: vpc-01--bgp-edge
spec:
  permit:
    external:
      name: bgp-edge
      prefixes:
      - prefix: 0.0.0.0/0
    vpc:
      name: vpc-01
      subnets:
      - default
```

### Example Edge side BGP configuration based on SONiC OS

!!! warning
    Hedgehog does not recommend using the following configuration for production. It is only provided as an example of
    Edge Peer configuration.

Interface configuration:

```
interface Ethernet2.100
 encapsulation dot1q vlan-id 100
 description switch-border--E1/2
 no shutdown
 ip vrf forwarding VrfHedge
 ip address 100.100.0.6/24
```

BGP configuration:

```
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

```
route-map HedgeIn permit 10
 match community Hedgehog
!
route-map HedgeOut permit 10
 set community 65102:5000
!

bgp community-list standard HedgeIn permit 5000:65102
```

See [Gateway Peering with NAT for External Connections](gateway.md#gateway-peering-for-external-connections) for examples on how to connect to external networks using NAT.

## Example 2: Static External

This example shows how to peer with the static `External` object with name `static-edge`,
given a Fabric VPC with name `vpc-01` on the Border Leaf `switch-border` that has a cable
connecting it to an Edge Device on port `E1/2`.

### Fabric API configuration

#### Static External

The external must be added to the wiring diagram:

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: static-edge
  namespace: default
spec:
  ipv4Namespace: default
  static:
    prefixes:
      - "0.0.0.0/0"
```

#### Connection

The connection should be specified in the wiring diagram:

```yaml
###
### switch-border--external--static-edge
###
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: switch-border--external--static-edge
spec:
  external:
    link:
      switch:
        port: switch-border/E1/2
```

#### Static ExternalAttachment

The following is a wiring configuration for the non-proxy version of the static external;
if desired, replace the `ip` line from the `static` configuration block with `proxy: true`.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalAttachment
metadata:
  name: switch-border--static-edge
spec:
  connection: switch-border--external--static-edge
  external: static-edge
  static:
    remoteIP: 192.168.30.1
    vlan: 35
    ip: 192.168.30.5/24
```

#### ExternalPeering

Assuming an external attachment without proxy, `vpc-01` can be peered with the external
using an `ExternalPeering` object:

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: ExternalPeering
metadata:
  name: vpc-01--static-edge
spec:
  permit:
    external:
      name: static-edge
      prefixes:
      - prefix: 0.0.0.0/0
    vpc:
      name: vpc-01
      subnets:
      - default
```

Alternatively, for the proxy version of the static external, use a Gateway peering:
```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-01--static-edge
  namespace: default
spec:
  gatewayGroup: default
  peering:
    ext.static-edge:
      expose:
      - default: true
    vpc-01:
      expose:
      - as:
        - cidr: 192.168.30.3/32 # or any other IP in the subnet configured on the Edge Device
        ips:
        - cidr: 10.0.1.0/24 # assuming this is the subnet in vpc-01 that we want to peer
        nat:
          masquerade: {}
```

### Example Edge side configuration based on SONiC OS

!!! warning
    Hedgehog does not recommend using the following configuration for production. It is only provided as an example.

Interface configuration:

```
interface Ethernet2.35
 encapsulation dot1q vlan-id 35
 description switch-border--E1/2
 no shutdown
 ip vrf forwarding VrfStatic
 ip address 192.168.30.1/24
```

Additionally, static routes must be configured on the Edge Device to make sure that traffic from the Fabric
can reach the advertised prefixes, and that return traffic can be routed back to the peered VPC.
As an example, assuming the Edge Device is connected to the target network via `Ethernet0` in VRF `VrfPublic`:

```
ip route vrf VrfStatic 0.0.0.0/0 192.168.89.1 interface Ethernet0 nexthop-vrf VrfPublic
ip route vrf VrfPublic 192.168.30.0/24 interface Ethernet2.35 nexthop-vrf VrfStatic
```

Finally, if traffic coming from the VPC must be able to go over the public Internet,
NAT should be configured on the Edge Device to masquerade the private IPs of the VPC.
