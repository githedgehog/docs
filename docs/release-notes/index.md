# Release notes

## Alpha-2

TBD

## Alpha-1

* Controller:
    * A single controller connecting to each switch management port. No redundancy.

* Controller requirements:
    * One 1 gig port per switch
    * One+ 1 gig+ ports connecting to the external management network.
    * 4 Cores, 12GB RAM, 100GB SSD.

* Seeder:
    * Seeder and Controller functions co-resident on the control node. Switch booting and ZTP on management ports directly connected to the controller.

* HHFab - the fabricator:
    * An operational tool to generate, initiate, and maintain the fabric software appliance.  Allows fabrication of the environment-specific image with all of the required underlay and security configuration baked in.

* DHCP Service:
    * A simple DHCP server for assigning IP addresses to hosts connecting to the fabric, optimized for use with VPC overlay.

* Topology:
    * Support for a Collapsed Core topology with 2 switch nodes.

* Underlay:
    * A simple single-VRF network with a BGP control plane.  IPv4 support only.

* External connectivity:
    * An edge router must be connected to selected ports of one or both switches.  IPv4 support only.

* Dual-homing:
    * L2 Dual homing with MCLAG is implemented to connect servers, storage, and other devices in the data center.  NIC bonding and LACP configuration at the host are required.

* VPC overlay implementation:
    * VPC is implemented as a set of ACLs within the underlay VRF. External connectivity to the VRF is performed via internally managed VLANs.  IPv4 support only.

* VPC Peering:
    * VPC peering is performed via ACLs with no fine-grained control.

* NAT
    * DNAT + SNAT are supported per VPC. SNAT and DNAT can’t be enabled per VPC simultaneously.

* Hardware support:
    * Please see the supported hardware list.

* Virtual Lab:
    * A simulation of the two-node Collapsed Core Topology as a virtual environment. Designed for use as a network simulation, a configuration scratchpad, or a training/demonstration tool.  Minimum requirements: 8 cores, 24GB RAM, 100GB SSD

* Limitations:
    * 40 VPCs max
    * 50 VPC peerings
    * [ 768 ACL entry platform limitation from Broadcom ]

* Software versions:
    * Fabricator: v0.5.2
    * Fabric: v0.18.6
    * Das-boot: v0.8.2
    * K3s: v1.27.4-k3s1
    * Zot: v1.4.3
    * SONiC: Broadcom Enterprise Base 4.1.1
