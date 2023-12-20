# External Peering

Hedgehog Fabric uses Border Leaf concept to exchange VPC routes outside the Fabric and providing L3 connectivity.
`External Peering` feature allows to set up an external peering endpoint and to enforce several policies between internal
and external endpoints.

>Hedgehog Fabric does not operate Edge side devices.

## Overview

Traffic exit from the Fabric is done on Border Leafs that are connected with Edge devices. Border Leafs are suitable to
terminate l2vpn connections and distinguish VPC L3 routable traffic towards Edge device as well as to land VPC servers. Border Leafs
(or Borders) can connect to several Edge devices.

>External Peering is only available on the switch devices that are capable for sub-interfaces.

### Connect Border Leaf to Edge device

In order to distinguish VPC traffic Edge device should be capable for
- Set up BGP IPv4 to advertise and receive routes from the Fabric
- Connect to Fabric Border Leaf over Vlan
- Be able to mark egress routes towards the Fabric with BGP Communities
- Be able to filter ingress routes from the Fabric by BGP Communities

All other filtering and processing of L3 Routed Fabric traffic should be done on the Edge devices.

### Control Plane

Fabric is sharing VPC routes with Edge devices via BGP. Peering is done over Vlan in IPv4 Unicast AFI/SAFI.

### Data Plane

VPC L3 routable traffic will be tagged with Vlan and sent to Edge device. Later processing of VPC traffic (NAT, PBR, etc) should
happen on Edge devices.

### VPC access to Edge device

Each VPC within the Fabric can ba allowed to access Edge devices. Additional filtering can be applied to the routes that
VPC can export to Edge devices and import from the Edge devices.

## API and implementation

### External

General configuration starts with specification of `External` objects. Each object of `External` type can represent a set of
Edge devices, or a single BGP instance on Edge device, or any other united Edge entities that can be described with following config

- Name of `External`
- Inbound routes are marked with dedicated BGP community
- Outbound routes are required to be marked with dedicated community

Each `External` should be bound to some VPC IP Namespace, otherwise prefixes overlap may happen.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: External
metadata:
  name: default--5835
spec:
  inboundCommunity: # BGP Standard Community of routes from Edge devices
  ipv4Namespace: # VPC IP Namespace
  outboundCommunity: # BGP Standard Community required to be assigned on prefixes advertised from Fabric
```

### Connection

`Connection` of type `external` is used to identify switch port on Border leaf that is cabled with an Edge device.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: # specified or generated
spec:
  external:
    link:
      switch:
        port: # SwtichName/EthernetXXX
```


### External Attachment

`External Attachment` is a definition of BGP Peering and traffic connectivity between a Border leaf and `External`.
Attachments are bound to `Connection` with type `external` and specify `Vlan` that will be used to segregate particular
Edge peering.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
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
    ip: # IP Address on the Border Leaf to set up BGP peering
    vlan: # Vlan ID to tag control and data traffic
```

Several `External Attachment` can be configured for the same `Connection` but for different `vlan`.

### External VPC Peering

To allow specific VPC have access to Edge devices VPC should be bound to specific `External` object. This is done via
`External Peering` object.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: ExternalPeering
metadata:
  name: # Name of ExternalPeering
spec:
  permit:
    external:
      name: # External Name
      prefixes: # List of prefixes(routes) to be allowed to pick up from External
      - # IPv4 Prefix
    vpc:
      name: # VPC Name
      subnets: # List of VPC subnets name to be allowed to have access to External (Edge)
      - # Name of the subnet within VPC

```
`Prefixes` can be specified as `exact match` or with mask range indicators `le` and `ge` keywords.
`le` is identifying prefixes lengths that are `less than or equal` and `ge` for prefixes lengths that are `greater than or equal`.

Example: Allow ANY IPv4 prefix that came from `External` - allow all prefixes that match default route with any prefix length
```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - le: 32
        prefix: 0.0.0.0/0
```
`ge` and `le` can also be combined.

Example: 
```yaml
spec:
  permit:
    external:
      name: ###
      prefixes:
      - le: 24
        ge: 16
        prefix: 77.0.0.0/8
```
For instance, `77.42.0.0/18` will be matched for given prefix rule above, but `77.128.77.128/25` or `77.10.0.0/16` won't.

## Examples

This example will show peering with `External` object with name `HedgeEdge` given Fabric VPC with name `vpc-1` on the Border
Leaf `switchBorder` that has a cable between an Edge device on the port `Ethernet42`. `vpc-1` is required to receive any prefixes
advertised from the `External`.

### Fabric API configuration

#### External
```console
# hhfctl external create --name HedgeEdge --ipns default --in 65102:5000 --out 5000:65102
```
```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: External
metadata:
  name: HedgeEdge
  namespace: default
spec:
  inboundCommunity: 65102:5000
  ipv4Namespace: default
  outboundCommunity: 5000:65102
```

#### Connection

Connection should be specified in the `wiring` diagram.

```yaml
###
### switchBorder--external--HedgeEdge
###
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Connection
metadata:
  name: switchBorder--external--HedgeEdge
spec:
  external:
    link:
      switch:
        port: switchBorder/Ethernet42
```

#### ExternalAttachment
Specified in `wiring` diagram
```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
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
apiVersion: vpc.githedgehog.com/v1alpha2
kind: ExternalPeering
metadata:
  name: vpc-1--HedgeEdge
spec:
  permit:
    external:
      name: HedgeEdge
      prefixes:
      - le: 32
        prefix: 0.0.0.0/0
    vpc:
      name: vpc-1
      subnets:
      - default
```
### Example Edge side BGP configuration based on SONiC OS

> **_NOTE:_** Hedgehog does not recommend to use SONiC OS as an Edge device. This example is used only as example of Edge Peer config

Interface config
```yaml
interface Ethernet2.100
 encapsulation dot1q vlan-id 100
 description switchBorder--Ethernet42
 no shutdown
 ip vrf forwarding VrfHedge
 ip address 100.100.0.6/24
```

BGP Config
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
Route Map configuration
```yaml
route-map HedgeIn permit 10
 match community Hedgehog
!
route-map HedgeOut permit 10
 set community 65102:5000
!

bgp community-list standard HedgeIn permit 5000:65102
```