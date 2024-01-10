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
# Hedgehog Network Fabric

The Hedgehog Open Network Fabric is an open source network architecture that provides connectivity between virtual and
physical workloads and provides a way to achieve network isolation between different groups of workloads using standar
BGP EVPN and vxlan technology. The fabric provides a standard kubernetes interfaces to manage the elements in the
physical network and provides a mechanism to configure virtual networks and define attachments to these virtual networks.
The Hedgehog Fabric provides isolation between different groups of workloads by placing them in different virtual
networks called VPC's. To achieve this we define different abstractions starting from the physical network where we
define `Connection` which defines how a physical server on the network connects to a physical switch on the fabric.

## Underlay Network

The Hedgehog Fabric currently support two underlay network topologies.

### Collapsed Core

A collapsed core topology is just a pair of switches connected in a mclag configuration with no other network elements.
All workloads attach to these two switches.

![image](./fabric-collapsedcore.png)

The leaf's in this setup are configured to be in a mclag pair and servers can either be connected to both switches as
a mclag port channel or as orphan ports connected to only one switch. both the leaves peer to external networks using
BGP and act as gateway for workloads attached to them. The configuration of the underlay in the collapsed core is very
simple and is ideal for very small deployments.

### Spine - Leaf

A spine-leaf topology is a standard clos network with workloads attaching to leaf switches and spines providing
connectivity between different leaves.

![image](./fabric-spineleaf.png)

This kind of topology is useful for bigger deployments and provides all the advantages of a typical clos network.
The underlay network is established using eBGP where each leaf has a separate ASN and peers will all spines in the
network. We used [RFC7938](https://datatracker.ietf.org/doc/html/rfc7938) as the reference for establishing the
underlay network.

## Overlay Network

The overlay network runs on top the underlay network to create a virtual network. The overlay network isolates control
and data plane traffic between different virtual networks and the underlay network. Vitualization is achieved in the
hedgehog fabric by encapsulating workload traffic over vxlan tunnels that are source and terminated on the leaf switches
in the network. The fabric using BGP-EVPN/Vxlan to enable creation and management of virtual networks on top of the
virtual. The fabric supports multiple virtual networks over the same underlay network to support multi-tenancy. Each
virtual network in the hedgehog fabric is identified by a VPC. In the following sections we will dive a bit deeper into
a high level overview of how are vpc's implemented in the hedgehog fabric and it's associated objects.

## VPC
We know what is a VPC and how to attach workloads to a specific VPC. Let us now take a look at how is this actually
implemented on the network to provice the view of a private network.

 - Each VPC is modeled as a vrf on each switch where there are VPC attachments defined for this vpc.
   The Vrf is allocated its own VNI. The Vrf is local to each switch and the VNI is global for the entire fabric. By
   mapping the vrf to a VNI and configuring an evpn instance in each vrf we establish a shared l3vni across the entire
   fabric. All vrf participating in this vni can freely communicate with each other without a need for a policy. A Vlan
   is allocated for each vrf which functions as a IRB Vlan for the vrf.
 - The vrf created on each switch corresponding to a VPC configures a BGP instance with evpn to advertise its locally
   attached subnets and import routes from its peered VPC's. The BGP instance in the tenant vrf's does not establish
   neighbor relationships and is purely used to advertise locally attached routes into the VPC (all vrf's with the same
   l3vni) across leafs in the network.
 - A VPC can have multuple subnets. Each Subnet in the VPC is modeled as a Vlan on the switch. The vlan is only locally
   significant and a given subnet might have different Vlan's on different leaves on the network. We assign a globally
   significant vni for each subnet. This VNI is used to extend the subnet across different leaves in the network and
   provides a view of single streched l2 domain if the applications need it.
 - The hedgehog fabric has a built-in DHCP server which will automatically assign IP addresses to each workload
   depending on the VPC it belongs to. This is achieved by configuring a DHCP relay on each of the server facing vlans.
   The DHCP server is accesible through the underlay network and is shared by all vpcs in the fabric. The inbuilt DHCP
   server is capable of identifying the source VPC of the request and assigning IP addresses from a pool allocated to the
   VPC at creation.
 - A VPC by default cannot communicate to anyone outside the VPC and we need to define specific peering rules to allow
   communication to external networks or to other VPCs.

## VPC Peering
To enable communication between 2 different VPC's we need to configure a VPC peering policy. The hedgehog fabric
supports two different peering modes.

- Local Peering - A local peering directly imports routers from the other VPC locally. This is achieved by a simple
  import route from the peer VPC. In case there are no locally attached worloads to the peer VPC the fabric
  automatically creates a stub vpc for peering and imports routes from it. This allows VPC's to peer with each other
  without the need for dedicated peering leaf. If a local peering is done for a pair of VPC's which have locally
  attached workloads the fabric automatically allocates a pair of ports on the switch to router traffic between these
  vrf's using static routes. This is required because of limitations in  the underlying platform. The net result of
  this is that the bandwidth between these 2 VPC's is limited by the bandwidth of the loopback interfaces allocated
  on the switch.
- Remote Peering  - Remote peering is implemented using a dedicated peering switch/switches which is used as a
  rendezvous point for the 2 VPC's in the fabric. The set of switches to be used for peering is determined by
  configuration in the peering policy. When a remote peering policy is applied for a pair of VPC's the vrf's
  corresponding to these VPC's on the peering switch advertise default routes into their specific vrf's identified
  by the l3vni. All traffic that does not belong to the VPC's is forwarded to the peering switch and which has routes
  to the other VPC's and gets forwarded from there. The bandwith limitation that exists in the local peering solution
  is solved here as the bandwith between the two VPC's is determined by the fabric cross section bandwidth.

<!-- @joggr:editLink(16328031-368b-4704-861e-2ada85a7a942):start -->
---
<a href="https://app.joggr.io/app/documents/16328031-368b-4704-861e-2ada85a7a942/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(16328031-368b-4704-861e-2ada85a7a942):end -->