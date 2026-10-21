# Multi-Fabric and Multi-Domain Deployments

!!! note
    This page is only relevant if a single controller has to manage more than one spine-leaf topology, or
    leaves connected to more than one set of spines. Other deployments can skip it: every object belongs to the
    `default` fabric and domain unless told otherwise, and nothing else in this guide needs to change.

Most of this user guide assumes a single CLOS topology where all leaves are connected to all spines, or at most a
mesh topology where leaves are connected to each other. You can remove some of the connections or even have disjoint
islands, but the API validation and the generated switch configuration were built around a simple 2-layer CLOS
topology in the underlay and a single EVPN domain in the overlay.

Modern datacenters, however, often need separate CLOS topologies for different functions. For example, a cluster for
AI disaggregated inference might have dedicated networks for prefill, decode, storage and management.
These networks are usually connected through border leaves, with some services and Internet access shared by a
subset of their hosts, but are otherwise separate. Until now, a cluster like this needed a separate Hedgehog
Fabric, each with its own controller, for every network.

Sticking to the same example, a CLOS topology is sometimes split into separate planes, with leaves connected to
separate spine sets. This is done, for example, to scale up bandwidth to the GPU hosts as their NICs increase in
capacity, without moving to a three-tier CLOS topology. Not all the nodes in the network can use separate planes,
though: some need a single egress, or have NICs that can not be broken out. These can be attached to leaves that
span several planes, and those leaves take care of routing between the planes. The objects described in the rest of
this user guide can model this, but nothing would stop routes or VPCs from spilling over from one spine set into the
other.

Two concepts cover these use cases: fabrics and domains.

## Fabrics and Domains

A **Fabric** is a single spine-leaf topology. It has its own switches, leaf ASN range, IPv4Namespaces, VPCs,
Externals and gateways. Fabrics are not cabled to each other: traffic between two fabrics goes through
[external systems](external.md), as it would between two separate installations. Servers and VLANNamespaces are not
tied to a fabric, so a server can be connected to more than one.

A **domain** is one spine set within a fabric, with its own spine ASN and gateway ASN. Domains are not separate
objects, they are listed in the Fabric. A spine is in exactly one domain; a leaf can be in several if it is connected
to the spines of each of them. Leaves in more than one domain are called shared leaves. The fabric keeps EVPN routes
from crossing between domains: two domains of the same fabric only exchange traffic through VPCs that are in both,
and those can only be attached to shared leaves.

```yaml
apiVersion: wiring.githedgehog.com/v1beta1
kind: Fabric
metadata:
  name: backend
  namespace: default
spec:
  leafASNStart: 4200001001  # this example uses 4-byte ASNs, but 2-byte ASNs also work
  leafASNEnd: 4200001999
  domains:
    plane-a:
      spineASN: 4200001000
      gatewayASN: 4200002000
    plane-b:
      spineASN: 4200003000
      gatewayASN: 4200004000
  disableBFD: false # optional, disables BFD between switches and on the gateway sessions
```

Use `kubectl get fabrics` to list fabrics and `kubectl fabric inspect fabric` to see the switches of each. The
`kubectl fabric inspect bgp`, `bfd` and `lldp` commands accept `--fabric` and `--domain` to only check the switches
of one fabric or domain.

### The Default Fabric

Any object that does not name a fabric is placed in `Fabric/default`, and any switch, VPC, External or gateway that
does not name a domain is placed in a domain called `default`. This is what keeps single-fabric wiring free of
fabric and domain references.

`Fabric/default` has a single domain named `default`, and should use the same ASNs as the Fabricator configuration
(`spineASN`, `leafASNStart`, `leafASNEnd` and the gateway `asn`). A new installation gets it from the wiring, see the
[sample wiring diagram](../install-upgrade/build-wiring.md#sample-wiring-diagram). When upgrading from a release
without fabrics, it is created from the Fabricator configuration, and every existing object is moved into it.

`Fabric/default` can not be deleted. Like any other fabric, its domains can not be changed once it is created, so a
deployment that needs several domains must create a new Fabric for them.

Here is an example of a topology with two fabrics. `fabric-a` is a spine-leaf topology with two domains;
`leaf-04` is shared and belongs to both domains. `fabric-b` is a mesh topology; the two fabrics are interconnected
via externals.

``` mermaid
graph TD

%% Style definitions
classDef gateway fill:#FFF2CC,stroke:#999,stroke-width:1px,color:#000
classDef spine   fill:#F8CECC,stroke:#B85450,stroke-width:1px,color:#000
classDef leaf    fill:#DAE8FC,stroke:#6C8EBF,stroke-width:1px,color:#000
classDef server  fill:#D5E8D4,stroke:#82B366,stroke-width:1px,color:#000
classDef eslag   fill:#FFF8E8,stroke:#CC9900,stroke-width:1px,color:#000
classDef external fill:#FFCC99,stroke:#D79B00,stroke-width:1px,color:#000
classDef hidden fill:none,stroke:none
classDef legendBox fill:white,stroke:#999,stroke-width:1px,color:#000

%% Network diagram
subgraph Fabric_Fabric_B["Fabric: fabric-b"]
	direction TB
subgraph Leaves_Fabric_B[" "]
	direction LR
	Leaf_05["leaf-05<br>server-leaf"]
	Leaf_06["leaf-06<br>server-leaf"]
end

subgraph Servers_Fabric_B[" "]
	direction TB
	Server_09["server-09"]
	Server_10["server-10"]
end

end
style Fabric_Fabric_B fill:#FAFAFA,stroke:#666,stroke-width:2px

subgraph Externals[" "]
	direction TB
	To_Fabric_A["to-fabric-a"]
	To_Fabric_B["to-fabric-b"]
end

subgraph Fabric_Fabric_A["Fabric: fabric-a"]
	direction TB
subgraph Domain_Fabric_A_Domain_B["Domain: domain-b"]
	direction TB
	Spine_03["spine-03<br>spine"]
	Spine_04["spine-04<br>spine"]
end
style Domain_Fabric_A_Domain_B fill:#EEF3F8,stroke:#6C8EBF,stroke-dasharray:5 5

subgraph Domain_Fabric_A_Domain_A["Domain: domain-a"]
	direction TB
	Spine_01["spine-01<br>spine"]
	Spine_02["spine-02<br>spine"]
end
style Domain_Fabric_A_Domain_A fill:#EEF3F8,stroke:#6C8EBF,stroke-dasharray:5 5

subgraph Leaves_Fabric_A[" "]
	direction LR
	Leaf_03["leaf-03<br>server-leaf"]
	Leaf_04["leaf-04<br>server-leaf"]

	subgraph Eslag_1 ["eslag-1"]
		direction LR
		Leaf_01["leaf-01<br>server-leaf"]
		Leaf_02["leaf-02<br>server-leaf"]
	end
end

subgraph Servers_Fabric_A[" "]
	direction TB
	Server_05["server-05"]
	Server_06["server-06"]
	Server_07["server-07"]
	Server_08["server-08"]
	Server_03["server-03"]
	Server_01["server-01"]
	Server_02["server-02"]
	Server_04["server-04"]
end

end
style Fabric_Fabric_A fill:#FAFAFA,stroke:#666,stroke-width:2px


%% Connections

%% Spine_01 -> Leaves
Spine_01 ---|"E1/4↔E1/1<br>E1/5↔E1/2"| Leaf_01
Spine_01 ---|"E1/5↔E1/3<br>E1/6↔E1/4"| Leaf_02
Spine_01 ---|"E1/4↔E1/5<br>E1/5↔E1/6"| Leaf_04

%% Spine_02 -> Leaves
Spine_02 ---|"E1/6↔E1/1<br>E1/7↔E1/2"| Leaf_01
Spine_02 ---|"E1/7↔E1/3<br>E1/8↔E1/4"| Leaf_02
Spine_02 ---|"E1/6↔E1/5<br>E1/7↔E1/6"| Leaf_04

%% Spine_03 -> Leaves
Spine_03 ---|"E1/4↔E1/1<br>E1/5↔E1/2"| Leaf_03
Spine_03 ---|"E1/8↔E1/3<br>E1/9↔E1/4"| Leaf_04

%% Spine_04 -> Leaves
Spine_04 ---|"E1/6↔E1/1<br>E1/7↔E1/2"| Leaf_03
Spine_04 ---|"E1/10↔E1/3<br>E1/11↔E1/4"| Leaf_04

%% Leaves -> Servers
Leaf_01 ---|"enp2s1↔E1/1"| Server_01
Leaf_01 ---|"enp2s1↔E1/2"| Server_02
Leaf_01 ---|"enp2s1↔E1/3"| Server_03

Leaf_02 ---|"enp2s2↔E1/1"| Server_01
Leaf_02 ---|"enp2s2↔E1/2"| Server_02
Leaf_02 ---|"enp2s1↔E1/3<br>enp2s2↔E1/4"| Server_04

Leaf_03 ---|"enp2s1↔E1/1"| Server_05
Leaf_03 ---|"enp2s1↔E1/2<br>enp2s2↔E1/3"| Server_06

Leaf_04 ---|"enp2s1↔E1/1"| Server_07
Leaf_04 ---|"enp2s1↔E1/2<br>enp2s2↔E1/3"| Server_08

Leaf_05 ---|"enp2s1↔E1/1"| Server_09

Leaf_06 ---|"enp2s1↔E1/1"| Server_10

%% Mesh connections
Leaf_05 ---|"E1/2↔E1/2<br>E1/3↔E1/3"| Leaf_06

%% External connections
Leaf_02 ---|"↔E1/9"| To_Fabric_B
Leaf_05 ---|"↔E1/4"| To_Fabric_A

To_Fabric_A ---|"interconnect"| To_Fabric_B

subgraph Legend["Network Connection Types"]
	direction LR
	%% Create invisible nodes for the start and end of each line
	L1(( )) --- |"Fabric Links"| L2(( ))
	L15(( )) --- |"Mesh Links"| L16(( ))
	L5(( )) --- |"Bundled Server Links (x2)"| L6(( ))
	L7(( )) --- |"Unbundled Server Links"| L8(( ))
	L9(( )) --- |"ESLAG Server Links"| L10(( ))
	L13(( )) --- |"External Links"| L14(( ))
	L19(( )) --- |"Fabric Interconnect Links"| L20(( ))
	P1(( )) --- |"Label Notation: Downstream ↔ Upstream"| P2(( ))
end

class Spine_01,Spine_02,Spine_03,Spine_04 spine
class Leaf_01,Leaf_02,Leaf_04,Leaf_03,Leaf_05,Leaf_06 leaf
class Server_03,Server_01,Server_02,Server_04,Server_07,Server_08,Server_05,Server_06,Server_09,Server_10 server
class To_Fabric_A,To_Fabric_B external
class Eslag_1 eslag
class L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,P1,P2,L13,L14,L15,L16,L19,L20 hidden
class Legend legendBox
linkStyle default stroke:#666,stroke-width:2px
linkStyle 0,1,2,3,4,5,6,7,8,9 stroke:#CC3333,stroke-width:4px
linkStyle 22 stroke:#0078D4,stroke-width:4px
linkStyle 15,17,19 stroke:#66CC66,stroke-width:4px
linkStyle 10,11,13,14 stroke:#CC9900,stroke-width:4px,stroke-dasharray:5 5
linkStyle 12,16,18,20,21 stroke:#999999,stroke-width:2px
linkStyle 23,24 stroke:#D79B00,stroke-width:2px
linkStyle 25 stroke:#9673A6,stroke-width:3px,stroke-dasharray:5 5
linkStyle 26 stroke:#B85450,stroke-width:2px
linkStyle 27 stroke:#0078D4,stroke-width:2px
linkStyle 28 stroke:#82B366,stroke-width:2px
linkStyle 29 stroke:#000000,stroke-width:2px
linkStyle 30 stroke:#CC9900,stroke-width:2px,stroke-dasharray:5 5
linkStyle 31 stroke:#D79B00,stroke-width:2px
linkStyle 32 stroke:#9673A6,stroke-width:2px,stroke-dasharray:5 5
linkStyle 33 stroke:#FFFFFF

%% Make subgraph containers invisible
style Leaves_Fabric_B fill:none,stroke:none
style Servers_Fabric_B fill:none,stroke:none
style Leaves_Fabric_A fill:none,stroke:none
style Servers_Fabric_A fill:none,stroke:none
style Externals fill:none,stroke:none
```

### Rules for Fabric Objects

- Domain names must be valid DNS labels.
- Each domain needs a spine ASN and a gateway ASN. These must be different from each other and outside the leaf
  ASN range.
- The leaf ASN ranges of two fabrics can not overlap, and no spine or gateway ASN can be used twice or fall in the leaf
  ASN range of any fabric.
- The leaf ASN range, the domains and their ASNs are fixed once the fabric is created. Domains can not be added,
  removed or renamed.
- A fabric can not be deleted while any object still references it.

## Placing Objects in a Fabric and Domain

Objects declare their fabric in `spec.topology.fabric` and, where relevant, their domain in `spec.topology.domain` or
`spec.topology.domains`. Neither is inferred from related objects: every object of a non-default fabric must set
its fabric, including connections, attachments and peerings. Switches, VPCs, Externals, gateways and gateway groups
must also set their domains, unless the fabric has a domain named `default`.

| Kind | Fabric | Domain |
|---|---|---|
| Switch | `topology.fabric` | `topology.domains`: exactly one for a spine, one or more for a leaf |
| VPC | `topology.fabric` | `topology.domains`: one or more |
| External | `topology.fabric` | `topology.domain` |
| Gateway, GatewayGroup | `topology.fabric` | `topology.domain` |
| Connection, SwitchGroup, IPv4Namespace, VPCAttachment, VPCPeering, ExternalAttachment, ExternalPeering, GatewayPeering | `topology.fabric` | - |

For example, a leaf connected to the spines of both domains of the `backend` fabric above:

```yaml
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: leaf-01
  namespace: default
spec:
  role: server-leaf
  topology:
    fabric: backend
    domains:
      - plane-a
      - plane-b
  # ...
```

Fabric and domain references can not be changed, and neither can the ASN of a switch. To move an object to another
fabric or domain, delete it and create it again.

`kubectl get` shows the fabric of every object and the domains of switches, VPCs, Externals, gateways and gateway
groups.

## Constraints

Most of the rules below exist because a mistake in a multi-domain topology does not cause an error. The fabric
would apply the configuration anyway, and then either leak routes from one domain into another or drop traffic
without saying why. The API catches these mistakes when the object is created instead.

Domains are kept apart by the spines: each spine drops EVPN routes whose AS path contains the spine ASN of another
domain. A shared leaf receives routes from the spines of all its domains, but anything it passed from one domain to
the other would carry the first domain's spine ASN and be dropped at the next spine. A shared leaf is therefore a
place where VPCs of both domains can be attached, never a path between the domains.

This only works for routes that went through a spine, and the switch and connection rules exclude the cases where
they don't. A mesh link and a gateway connection both make a leaf pass on the VTEPs it learned from other switches, and
routes from an external system enter at the border leaf with no spine ASN in their path. On a shared leaf, any of
these would carry routes from one domain into the other, so these connections require a switch in a single domain.
Similarly, switches of a redundancy group in different domains would never exchange the EVPN routes that ESLAG needs.

The other rules make sure that objects that are meant to work together meet on some switch. If a VPC could be
attached both to a leaf only in `plane-a` and to a leaf only in `plane-b`, its hosts on the two leaves would not
reach each other, because the VPC's routes never cross from one domain to the other. In the same way, a peering
between two VPCs without a common domain would be accepted but never carry traffic.

Objects can only reference objects in their own fabric: a connection and its switches, a VPC and its IPv4Namespace, an
attachment and the switches it uses, the two sides of a peering, and so on. On top of that, the API enforces the
following domain rules.

Switches and connections:

- A leaf's ASN must be in its fabric's leaf ASN range, and a spine's ASN must be its domain's spine ASN.
- Switches in the same redundancy group must be in the same domains.
- A leaf must be in the domain of every spine it is connected to.
- Both leaves of a mesh connection must be in the same single domain.
- A switch with a gateway, external or static external connection must be in exactly one domain, so shared leaves
  can not connect to gateways or external systems.

Attachments:

- A VPC can only be attached to switches that are in all of its domains.
- An External can only be attached to switches in its domain.
- A gateway's ASN must be its domain's gateway ASN, and it can only be connected to switches in that domain. It can
  only join gateway groups of the same domain.

Peerings:

- Two VPCs can only be peered if they have at least one domain in common.
- An External can only be peered with VPCs that are in its domain.
- A GatewayPeering's gateway group must be in one of the domains of each VPC it peers, and in the domain of each
  External.
- A VPC can only [relay DHCP to another VPC](vpcs.md#dhcp-relay-to-another-vpc) in the same fabric and with at least
  one domain in common.

## Connecting Fabrics Through Externals

Fabrics reach each other through external systems, connected to the border leaves of each fabric as described in
[External Peering](external.md).

A fabric drops routes whose AS path contains one of its own ASNs, so the neighbor ASN of an External attachment
can not be an ASN of its own fabric. Using an ASN of another fabric only produces a warning: the two fabrics will
not be able to exchange routes through that external system, which may or may not be what you want.

Domains of the same fabric can not reach each other through an external system: routes from one domain carry its
spine ASN, and the spines of the other domain drop them.

An External can present a single [local ASN](external.md#local-asn) to the external system on all its attachments.
The same rules apply to it: it can not be an ASN of the External's own fabric, and it produces a warning if it is an
ASN of another fabric or the local ASN of an External in another fabric. Two fabrics using the same local ASN can
not reach each other through external systems.
