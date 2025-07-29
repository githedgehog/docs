# Release notes

!!! note
    Please consult [this page](../known-limitations/known-limitations.md) for a list of current limitations
    of the Fabric. Unless otherwise stated, these issues affect all the latest versions of Fabric.

## 25.04

!!! note
    It's only possible to upgrade from 25.03 to 25.04 and requires all switches to run Broadcom SONiC 4.5.0.

### Highlights

- More efficient and reliable Fabric BGP configuration
    - Only a single L2VPN EVPN neighbor between the pair of leaf and spine switches (instead of per physical link)
    - BFD (Bidirectional Forwarding Detection) is enabled for physical links between leaf and spine switches for better
      fault detection and recovery
    - Only minimally necessary routes are now advertised
- Externals are now using dedicated VRFs on the switches to provide better isolation and security
- Switch agent is now collecting more info from the switch about transceivers (e.g. CMIS, laser power, etc.)
    - Could be accessed via inspect commands (e.g. `kubectl fabric inspect switch -n <switch-name> --ports --transceivers --lasers`)
- Celestica DS2000 is now supported as a leaf and spine
    - (Broadcom TD3-X5 2.0T) 48xSFP28-25G, 8xQSFP28-100G

### Other

- Loopback workaround fully deprecated and not configurable anymore
- Grafana Alloy updated to version v1.9.2

### Software versions

- fabricator/hhfab: v0.41.1
- fabric: v0.87.3
- broadcom sonic: 4.5.0
- flatcar: v4152.2.3
- k8s (k3s): v1.33.2-k3s1

## 25.03

### Highlights

- RoCE v2 (RDMA over Converged Ethernet version 2) support
    - Pre-configured lossless buffers with the corresponding QoS configuration including ECN (Explicit Congestion
      Notification) and PFC (Priority Flow Control)
    - ECMP RoCE QPN (Queue Pair Number) hashing support for even traffic distribution
- Celestica DS5000 is now supported as a leaf while using L3VNI VPC mode (in addition to the full spine role support)
- Loopback Workaround (VPCLoopback Connections) is no longer required for local peering

### Other

- Support for Broadcom SONiC 4.5.0 (see [upgrade SONiC](../install-upgrade/upgrade.md#upgrade-sonic)) for instructions
- New L3VNI VPC mode that only uses L3VNI on the switches allowing TH5 switches to play the leaf role while fully
  supporting multi-tenancy (VPCs) and external peering
    - Regular (L2VNI) VPC mode requires support for both L2VNI and L3VNI on the switches
- Included DHCP server is more configurable now
    - It is now possible to disable the default route advertisement and to advertise custom routes
    - The DHCP lease time is now configurable (default is 1 hour)
- Interface queues and WRED ECN counters are now collected and available through the `inspect port` commands and
  Prometheus integration

### Software versions

- fabricator/hhfab: v0.40.0
- fabric: v0.81.1
- broadcom sonic: 4.5.0
- flatcar: v4152.2.3
- k8s (k3s): v1.32.4-k3s1

## 25.02

### Highlights

- Celestica DS5000 support as a spine and limited leaf
    - Limited leaf means that [local peering](../install-upgrade/build-wiring/#local-vpc-peering) is not supported and
      externals could only be attached without VLANs due to the lack of subinterfaces support
- MCLAG link state tracking is now enabled (shutdown server-facing MCLAG port channels if no spine uplinks are up)

### Tools

- (Experimental) support dump could be created by running `kubectl hhfab support dump`
    - Note: As this is an experimental feature, it may be unstable or subject to change in future releases
    - It includes all regularly requested data from the K8s API, controller logs, etc.
- `kubectl fabric switch ssh` now accepts `--run` to pass command to run on the switch
- k9s now allows to use `l` (lowercase `L` shortcut) to open the switch agent logs (works for both switches and agents)
- SSH Agent Forwarding could be used to avoid typing the switch password each time for `kubectl fabric` or `k9s`
    - For more details, see [SSH Agent Forwarding documentation](https://www.ssh.com/academy/ssh/agent)

### Other

- IPv4 and VLAN namespaces are now mutable
- MCLAG and ESLAG connections could be created with a single port
- Flatcar and K8s updates

### Software versions

- fabricator/hhfab: v0.38.1
- fabric: v0.75.3
- broadcom sonic: 4.4.2
- flatcar: v4152.2.3
- k8s (k3s): v1.32.4-k3s1

## 25.01

### Highlights

- Broadcom SONiC 4.4.2 support (see [upgrade
  SONiC](../install-upgrade/upgrade.md#upgrade-sonic)) for instructions
- Support for Celestica DS4101 as a spine
- Fabric agent is periodically enforcing the switch configuration
- All nodes (e.g. control node) and switches are automatically configured to use NTP server from the control node
- User can choose to enable all switch ports by default by setting `enableAllPorts` to `true` on the Switch object
- Control node OS (Flatcar) and K8s are now automatically upgraded

### Tools

- `kubectl fabric inspect` now supports LLDP and BGP neighbors inspection
    - it shows expected and actual values observed on a switches
    - use `--strict` flag to make inspect fail if expected neighbors are not matching
- `kubectl fabric switch reboot` is more reliable now and we'll retry if it fails
- `kubectl fabric switch reinstall` now handles ONIE grub as well and reboots switch into ONIE NOS Install mode
- `hhfab diagram` can now generate Draw.io, Graphviz (dot) and Mermaid diagrams

### Software versions

- fabricator/hhfab: v0.36.1
- fabric: v0.71.6
- broadcom sonic: 4.4.2
- flatcar: v4152.2.0
- k8s (k3s): v1.32.1-k3s1

## 24.09

### Device Support

- Dell Z9332 as a spine-only switch

### Fabric Lifecycle Management

- Installer ISO builder for zero-touch control node installation
- CLI for exporting Wiring Diagram
- CLI for exporting Fabricator configs
- Automated update mechanism from B1 release, including airgap support

### Software versions

- fabricator/hhfab: v0.32.1
- fabric: v0.58.0
- broadcom sonic: 4.4.0
- flatcar: v4081.2.0
- k8s (k3s): v1.31.1-k3s1

## Beta-1

### Device support

- Celestica DS4000 as a spine

### SONiC

- Broadcom SONiC 4.4.0 support

### Fabric provisioning, management

- Out-of-band management network connectivity
- Deprecated support for in-band management network connectivity, chain boot, and front-panel boot until further notice
- Automatic zero touch switch provisioning [ ZTP ] is based on the serial number or the first management interface MAC address
- Full support for airgap installations and upgrades by default
- Self-contained USB image generation for control node installation
- Automated in-place upgrades for control node(s) moving forward

### API

- API version v1beta1
- Guaranteed backward compatibility moving forward

## Alpha-7

### Device Support

New devices supported by the fabric:

- Clos Spine
    - Celestica DS3000
    - Edgecore AS7712-32X-EC
    - Supermicro SSE-C4632SB

- Clos Leaf
    - Celestica DS3000
    - Supermicro SSE-C4632SB

- Collapsed Core ToR
    - Celestica DS3000
    - Supermicro SSE-C4632SB

### SwitchProfiles

- Metadata describing switch capabilities, feature capacities, and resource naming mapping.
- Switch Profiles are used for providing normalized name/id mapping, validation and internal resource management.
- Switch Profiles are Mandatory. Each switch model must have a corresponding switch profile to be supported by the fabric.
- Each switch defined in the wiring diagram should be pointing to the switch profile document.
- [Detailed overview](../user-guide/profiles.md)
- [Catalog of switch profiles](../reference/profiles.md)

### New Universal Port Naming Scheme

- `E<asic>/<port>/<breakout>` or `M<port>`
- Enabled via switch profiles

### Improved per switch-model/platform validation

- Enabled via switch profiles

### VPC

- It’s now possible to explicitly specify a gateway to use in VPC subnets
- StaticExternal now supports default routes

### Inspection CLI

CLI commands are intended to navigate fabric configuration and state and allow introspection of the dependencies and cross-domain checking:

- Fabric (overall control nodes and switches overview incl. status, serials, etc.)
- Switch (status, used ports, counters, etc.)
- Switch sort (connection if used in one, counters, VPC and External attachments, etc.)
- Server (connection if used in one, VPC attachments, etc.)
- Connection (incl. VPC and External attachments, Loobpback Workaround usage, etc.)
- VPC/VPCSubnet (incl. where is it attached and what's reachable from it)
- IP Address (incl. IPv4Namespace, VPCSubnet and DHCPLease or External/StaticExternal usage)
- MAC Address (incl. switch ports and DHCP leases)
- Access between pair of IPs, Server names or VPCSubnets (everything except external IPs will be translated to VPCSubnets)

# Observability

- Example Grafana Dashboards [added to the docs](../user-guide/grafana.md)
- Syslog (`/var/log/syslog`) is now could be collected from all switches and forwarded to Loki targets

# Bug Fixes

- Fixed: Restricted subnet isn't accessible from other subnets of the same VPC


## Alpha-6

### Observability

#### Telemetry - Prometheus Exporter

* Hedgehog Fabric Control Plane Agents on switches function as Prometheus Exporters

* Telemetry data provided by Broadcom SONiC is now supported:
    * port and interface status and counters
    * transceiver state
    * environmental information (temperature, fans, psu, etc.)
    * BGP state and counters

* Export to Prometheus using Prometheus Remote-Write API or any API-compatible platform

#### Logging

* [Grafana Alloy](https://grafana.com/docs/alloy/latest/) is supported as a certified logging agent that is installed
and managed by the Fabric

* Data collected
    * Agent logs
    * Agent, switch, and host-level metrics

* Export to API-compliant platforms and products such as Prometheus, Loki, Grafana Cloud, or any LGTM stack

#### Agent Status API Enhancements

* Ports status and counters
* Port breakout status and counters
* Transceiver status and counters
* Environmental and platform information
* LLDP neighbors

### Networking enhancements

* Multiple direct control links per switch are now supported
* Custom static routes could be installed into VPC using API
* ExternalAttachment could be configured without VLAN now

### Other improvements

* PXE boot with HTTP
* The `hhfab` and `hhfctl` (kubectl plugin) are now published for Linux/MacOS amd64/arm64
* Switch users can now be configured as part of installation preparation  (username, password hash, role, and public
  keys)

### Bugs fixed

* DHCP service assigning IP multiple times if restarted in between
* Remote peering was configured as a local


## Alpha-5

### Open Source

* Apache License 2.0
* The main repos are [public](https://github.com/githedgehog):
    * Fabric
    * Fabricator
    * Das-boot
    * Toolbox
    * Docs
* Items not open-sourced:
    * HONIE with front panel booting support

### DHCP/PXE boot support for multi-homed connections

* PXE URL support for on-demand DHCP service
* LACP link (MCLAG and ESLAG) fallback allows support of one of the links without the use of a host-level bond

### Improvements

* Native VLAN support for server-facing connections
* Extended wiring validation at hhfab init/build time
* External peering failover in case of using remote peering on the same switches as external connectivity

## Alpha-4

### Documentation

* Fabric API reference

### Host connectivity dual homing improvements

* ESI for VXLAN-based BGP EVPN
  * Support in Fabric and VLAB
* Host connectivity Redundancy Groups
  * Groups LEAF switches to provide multi-homed connectivity to the Fabric
  * 2-4 switches per group
  * Support for MCLAG and ESLAG (EVPN MH / ESI)
  * A single redundancy group can only support multi-homing of one type (ESLAG or MCLAG)
  * Multiple types of redundancy groups can be used in the fabric simultaneously

### Improved VPC security policy - better Zero Trust

* Inter-VPC
    * Allow inter-VPC and external peering with per subnet control
* Intra-VPC intra-subnet policies
    * Isolated Subnets
        * subnets isolated by default from other subnets in the VPC
        * require a user-defined explicitly permit list to allow communications to other subnets within the VPC
        * can be set on individual subnets within VPC or per entire VPC - off by default
        * Inter-VPC and external peering configurations are not affected and work the same as before
    * Restricted Subnets
        * Hosts within a subnet have no mutual reachability
        * Hosts within a subnet can be reached by members of other subnets or peered VPCs as specified by the policy
        * Inter-VPC and external peering configurations are not affected and work the same as before
    * Permit Lists
        * Intra-VPC Permit Lists govern connectivity between subnets within the VPC for isolated subnets
        * Inter-VPC Permit Lists govern which subnets of one VPC have access to some subnets of the other VPC for finer-grained control of inter-VPC and external peering

### Static External Connection

* Allows access between hosts within the VPC and devices attached to a switch with user-defined static routes

### Internal Improvements

* A new, more reliable automated ID allocation system
* Extra validation of object lifecycle (e.g., object-in-use removal validation)

### Known Issues

* External Peering Failover
    * Conditions: ExternalPeering is specified for the VPC, and the same VPC has Border Leaf VPCPeering
    * Issue: Detaching ExternalPeering may cause VPCPeering on the Border Leaf group to stop working
    * Workaround: VPCPeering on the Border Leaf group should be recreated



## Alpha-3

### SONiC support

* Broadcom Enterprise SONiC 4.2.0 (previously 4.1.1)

### Multiple IPv4 namespaces

* Support for multiple overlapping IPv4 addresses in the Fabric
* Integrated with on-demand DHCP Service (see below)
* All IPv4 addresses within a given VPC must be unique
* Only VPCs with non-overlapping IPv4 subnets can peer within the Fabric
* An external NAT device is required for peering of VPCs with overlapping subnets

### Hedgehog Fabric DHCP and IPAM Service

* Custom DHCP server executing in the controllers
* Multiple IPv4 namespaces with overlapping subnets
* Multiple VLAN namespaces with overlapping VLAN ranges
* DHCP leases exposed through the Fabric API
* Available for VLAB as well as the Fabric

### Hedgehog Fabric NTP Service

* Custom NTP servers at the controller
* Switches automatically configured to use control node as NTP server
* NTP servers can be configured to sync to external time/NTP server

### StaticExternal connections

* Directly connect external infrastructure services (such as NTP, DHCP, DNS) to the Fabric
* No BGP is required, just automatically configured  static routes

### DHCP Relay to 3rd party DHCP service
Support for 3rd party DHCP server (DHCP Relay config) through the API


## Alpha-2

### Controller

A single controller. No controller redundancy.

### Controller connectivity

For CLOS/LEAF-SPINE fabrics, it is recommended that the controller connects to one or more leaf switches in the fabric on front-facing data ports. Connection to two or more leaf switches is recommended for redundancy and performance. No port break-out functionality is supported for controller connectivity.

Spine controller connectivity is not supported.

For Collapsed Core topology, the controller can connect on front-facing data ports, as described above, or on management ports. Note that every switch in the collapsed core topology must be connected to the controller.

Management port connectivity can also be supported for CLOS/LEAF-SPINE topology but requires all switches connected to the controllers via management ports. No chain booting is possible for this configuration.

### Controller requirements

* One  1 gig+ port per to connect to each controller attached switch
* One+ 1 gig+ ports connecting to the external management network.
* 4 Cores, 12GB RAM, 100GB SSD.

### Chain booting

Switches not directly connecting to the controllers can chain boot via the data network.

### Topology support

CLOS/LEAF-SPINE and Collapsed Core topologies are supported.

#### LEAF Roles for CLOS topology

server leaf, border leaf, and mixed leaf modes are supported.

#### Collapsed Core Topology

Two ToR/LEAF switches with MCLAG server connection.

### Server multihoming

MCLAG-only.

### Device support

#### LEAFs

* DELL:
    * S5248F-ON
    * S5232F-ON

* Edge-Core:
    * DCS204 (AS7726-32X)
    * DCS203 (AS7326-56X)
    * EPS203 (AS4630-54NPE)

#### SPINEs

* DELL:
    * S5232F-ON
* Edge-Core:
    * DCS204 (AS7726-32X)

### Underlay configuration:

Port speed, port group speed, port breakouts are configurable through the API

### VPC (overlay) Implementation

VXLAN-based BGP eVPN.

### Multi-subnet VPCs

A VPC consists of subnets, each with a user-specified VLAN for external host/server connectivity.

### Multiple IP address namespaces

Multiple IP address namespaces are supported per fabric. Each VPC belongs to the corresponding IPv4 namespace. There are no subnet overlaps within a single IPv4 namespace. IP address namespaces can mutually overlap.

### VLAN Namespace

VLAN Namespaces guarantee the uniqueness of VLANs for a set of participating devices. Each switch belongs to a list of VLAN namespaces with non-overlapping VLAN ranges. Each VPC belongs to the VLAN namespace. There are no VLAN overlaps within a single VLAN namespace.

This feature is useful when multiple VM-management domains (like separate VMware clusters connect to the fabric).

### Switch Groups

Each switch belongs to a list of switch groups used for identifying redundancy groups for things like external connectivity.

### Mutual VPC Peering

VPC peering is supported and possible between a pair of VPCs that belong to the same IPv4 and VLAN namespaces.

### External VPC Peering

VPC peering provides the means of peering with external networking devices (edge routers, firewalls, or data center interconnects). VPC egress/ingress is pinned to a specific group of the border or mixed leaf switches. Multiple “external systems” with multiple devices/links in each of them are supported.

The user controls what subnets/prefixes to import and export from/to the external system.

No NAT function is supported for external peering.

### Host connectivity

Servers can be attached as Unbundled, Bundled (LAG) and MCLAG

### DHCP Service

VPC is provided with an optional DHCP service with simple IPAM

### Local VPC peering loopbacks

To enable local inter-vpc peering that allows routing of traffic between VPCs, local loopbacks are required to overcome silicon limitations.

### Scale

* Maximum fabric size: 20 LEAF/ToR switches.
* Routes per switch: 64k
  * [ silicon platform limitation in Trident 3; limits to number of endpoints in the fabric  ]
* Total VPCs per switch: up to 1000
  * [ Including VPCs attached at the given switch and VPCs peered with ]
* Total VPCs per VLAN namespace: up to 3000
  * [ assuming 1 subnet per VPC ]
* Total VPCs per fabric:  unlimited
  * [ if using multiple VLAN namespaces ]
* VPC subnets per switch: up to 3000
* VPC subnets per VLAN namespace up to 3000
* Subnets per VPC: up to 20
  * [ just a validation; the current design allows up to 100, but it could be increased even more in the future ]
* VPC Slots per remote peering @ switch: 2
* Max VPC loopbacks per switch: 500
  * [ VPC loopback workarounds per switch are needed for local peering when both VPCs are attached to the switch or for external peering with VPC attached on the same switch that is peering with external ]

### Software versions

* Fabric: v0.23.0
* Das-boot: v0.11.4
* Fabricator: v0.8.0
* K3s: v1.27.4-k3s1
* Zot: v1.4.3
* SONiC
  * Broadcom Enterprise Base 4.1.1
  * Broadcom Enterprise Campus 4.1.1

### Known Limitations

* MTU setting inflexibility:
  * Fabric MTU is 9100 and not configurable right now (A3 planned)
  * Server-facing MTU is 9136 and not configurable right now (A3+)
* no support for Access VLANs for attaching servers (A3 planned)
* VPC peering is enabled on all subnets of the participating VPCs. No subnet selection for peering. (A3 planned)
* peering with external is only possible with a VLAN (by design)
* If you have VPCs with remote peering on a switch group, you can't attach those VPCs on that switch group (by definition of remote peering)
* if a group of VPCs has remote peering on a switch group, any other VPC that will peer with those VPCs remotely will need to use the same switch group (by design)
* if VPC peers with external, it can only be remotely peered with on the same switches that have a connection to that external (by design)
* the server-facing connection object is immutable as it’s very easy to get into a deadlock, re-create to change it (A3+)


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
    * DNAT + SNAT are supported per VPC. SNAT and DNAT can't be enabled per VPC simultaneously.

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
