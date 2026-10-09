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
