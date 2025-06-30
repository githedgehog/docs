# VPCs and Namespaces

## VPC

A Virtual Private Cloud (VPC) is similar to a public cloud VPC. It provides an isolated private network with support for multiple subnets,
each with user-defined VLANs and optional DHCP services.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  ipv4Namespace: default # Limits which subnets can the VPC use to guarantee non-overlapping IPv4 ranges
  vlanNamespace: default # Limits which Vlan Ids can the VPC use to guarantee non-overlapping VLANs
  mode: ""  # Empty string is the default meaning l2vni, other option is l3vni

  defaultIsolated: true # Sets default behavior for the current VPC subnets to be isolated
  defaultRestricted: true # Sets default behavior for the current VPC subnets to be restricted

  subnets:
    default: # Each subnet is named, "default" subnet isn't required, but actively used by CLI
      dhcp:
        enable: true # On-demand DHCP server
        range: # Optionally, start/end range could be specified, otherwise all available IPs are used
          start: 10.10.1.10
          end: 10.10.1.99
        options: # Optional, additional DHCP options to enable for DHCP server, only available when enable is true
          pxeURL: tftp://10.10.10.99/bootfilename # PXEURL (optional) to identify the PXE server to use to boot hosts; HTTP query strings are not supported
          dnsServers: # (optional) configure DNS servers
            - 1.1.1.1
          timeServers: # (optional) configure Time (NTP) Servers
            - 1.1.1.1
          interfaceMTU: 1500 # (optional) configure the MTU (default is 9036); doesn't affect the actual MTU of the switch interfaces
      subnet: 10.10.1.0/24 # User-defined subnet from ipv4 namespace
      gateway: 10.10.1.1 # User-defined gateway (optional, default is .1)
      vlan: 1001 # User-defined VLAN from VLAN namespace
      isolated: true # Makes subnet isolated from other subnets within the VPC (doesn't affect VPC peering)
      restricted: true # Causes all hosts in the subnet to be isolated from each other

    thrird-party-dhcp: # Another subnet
      dhcp:
        relay: 10.99.0.100/24 # Use third-party DHCP server (DHCP relay configuration), access to it could be enabled using StaticExternal connection
      subnet: "10.10.2.0/24"
      vlan: 1002

    another-subnet: # Minimal configuration is just a name, subnet and VLAN
      subnet: 10.10.100.0/24
      vlan: 1100

  permit: # Defines which subnets of the current VPC can communicate to each other, applied on top of subnets "isolated" flag (doesn't affect VPC peering)
    - [subnet-1, subnet-2, subnet-3] # 1, 2 and 3 subnets can communicate to each other
    - [subnet-4, subnet-5] # Possible to define multiple lists

  staticRoutes: # Optional, static routes to be added to the VPC. Will not be exported when peering
    - prefix: 10.100.0.0/24 # Destination prefix
      nextHops: # Next hop IP addresses
        - 10.200.0.0
```

### Isolated and restricted subnets, permit lists

Subnets can be isolated and restricted, with the ability to define permit lists to allow communication between specific
isolated subnets. The permit list is applied on top of the isolated flag and doesn't affect VPC peering.

_Isolated subnet_ means that the subnet has no connectivity with other subnets within the VPC, but it could still be
allowed by permit lists.

_Restricted subnet_ means that all hosts in the subnet are isolated from each other within the subnet.

A Permit list contains a list. Every element of the list is a set of subnets that can communicate with each other.


### Third-party DHCP server configuration

In case you use a third-party DHCP server, by configuring `spec.subnets.<subnet>.dhcp.relay`, additional information is
added to the DHCP packet forwarded to the DHCP server to make it possible to identify the VPC and subnet. This
information is added under the RelayAgentInfo (option 82) in the DHCP packet. The relay sets two suboptions in the
packet:

* _VirtualSubnetSelection_ (suboption 151) is populated with the VRF which uniquely identifies a VPC on the Hedgehog
  Fabric and will be in `VrfV<VPC-name>` format, for example `VrfVvpc-1` for a VPC named `vpc-1` in the Fabric API.
* _CircuitID_ (suboption 1) identifies the VLAN which, together with the VRF (VPC) name, maps to a specific VPC subnet.

## VPCAttachment

A VPCAttachment represents a specific VPC subnet assignment to the `Connection` object which means a binding between an
exact server port and a VPC.
It basically leads to the VPC being available on the specific server port(s) on a subnet VLAN.

VPC could be attached to a switch that is part of the VLAN namespace used by the VPC.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPCAttachment
metadata:
  name: vpc-1-server-1--mclag--s5248-01--s5248-02
  namespace: default
spec:
  connection: server-1--mclag--s5248-01--s5248-02 # Connection name representing the server port(s)
  subnet: vpc-1/default # VPC subnet name
  nativeVLAN: true # (Optional) if true, the port will be configured as a native VLAN port (untagged)
```

## VPCPeering

A VPCPeering enables VPC-to-VPC connectivity. There are two types of VPC peering:

* Local: peering is implemented on the same switches where VPCs are attached
* Remote: peering is implemented on the border/mixed leaves defined by the `SwitchGroup` object

VPC peering is only possible between VPCs attached to the same IPv4 namespace (see [IPv4Namespace](#ipv4namespace)).

Note that static routes defined within a VPC will not be exported to other VPC peers.

### Local VPC peering

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPCPeering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  permit: # Defines a pair of VPCs to peer
  - vpc-1: {} # Meaning all subnets of two VPCs will be able to communicate with each other
    vpc-2: {} # See "Subnet filtering" for more advanced configuration
```

### Remote VPC peering

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPCPeering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  permit:
  - vpc-1: {}
    vpc-2: {}
  remote: border # Indicates a switch group to implement the peering on
```

### Subnet filtering

It's possible to specify which specific subnets of the peering VPCs could communicate to each other using the `permit`
field.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPCPeering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  permit: # subnet-1 and subnet-2 of vpc-1 could communicate to subnet-3 of vpc-2 as well as subnet-4 of vpc-2 could communicate to subnet-5 and subnet-6 of vpc-2
  - vpc-1:
      subnets: [subnet-1, subnet-2]
    vpc-2:
      subnets: [subnet-3]
  - vpc-1:
      subnets: [subnet-4]
    vpc-2:
      subnets: [subnet-5, subnet-6]
```

## IPv4Namespace

An `IPv4Namespace` defines a set of (non-overlapping) IPv4 address ranges available for use by VPC subnets.
Each VPC belongs to a specific IPv4 namespace. Therefore, its subnet prefixes must be from that IPv4 namespace.

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: IPv4Namespace
metadata:
  name: default
  namespace: default
spec:
  subnets: # List of prefixes that VPCs can pick their subnets from
  - 10.10.0.0/16
```

## VLANNamespace

A `VLANNamespace` defines a set of VLAN ranges available for attaching servers to switches. Each switch can belong to one or more
disjoint VLANNamespaces.

```yaml
apiVersion: wiring.githedgehog.com/v1beta1
kind: VLANNamespace
metadata:
  name: default
  namespace: default
spec:
  ranges: # List of VLAN ranges that VPCs can pick their subnet VLANs from
  - from: 1000
    to: 2999
```

## Mode

VPCs can operate in two modes: L2VNI and L3VNI. L2VNI is the default mode of
operation and represents the conventional functionality. L3VNI is designed
for switches that lack the hardware support for L2VNI.

### L2VNI Mode

This is the conventional multi-tenant network virtualization mode. It is the
default option for VPCs.


### L3VNI Mode

In L3VNI mode, the switches are configured to exclusively route unicast traffic.
This enables multi-tenancy inside of a fabric, even with switches of mixed
capabilities. The [DS5000](../reference/profiles.md#celestica-ds5000) is an
L3-only leaf and VPCs attached to this switch must be in L3VNI mode. VPCs in
L3VNI mode are not able to use switches configured for ESLAG.

Without broadcast traffic, each end host needs to have a full /32 address for
its address (e.g., `10.10.0.5/32`, not `10.10.0.5/24`). The host also
needs to emit traffic containing its IP-to-MAC mapping before the network will be
able to route traffic to it, as there is no MAC learning.

The DHCP server included with the Fabric has been updated to support L3VNI
mode. When a VPC is using the included DHCP server and is in L3VNI mode,
the DHCP server will send a DHCP lease with a short duration, so that the DHCP client will immediately request a new
lease. The DHCP renewal traffic allows the network to detect the host and redistribute the route via BGP. 
Subsequent lease requests will use the configured lease duration.

If a user elects to use their own DHCP server or statically assign IP addresses, it
is recommended that the user set the following `sysctl` values on the end hosts:

```console
net.ipv4.conf.default.arp_notify=1
net.ipv4.conf.default.arp_announce=1
```

#### Example Route Output

If the fabric DHCP server is enabled and serving a default route:

```console
user@server ~$ ip route
default via 10.10.0.1 dev enp2s1.1000 proto dhcp src 10.10.0.4 metric 1024
10.10.0.1 dev enp2s1.1000 proto dhcp scope link src 10.10.0.4 metric 1024 # Route for VPC subnet gateway
```
If the fabric DHCP server is enabled and not serving a default route:

```console
user@server ~$ ip route
10.10.0.1/24 via 10.10.0.1 dev enp2s1.1000 proto dhcp src 10.10.0.4 metric 1024 # Route for VPC subnet gateway
10.10.0.1 dev enp2s1.1000 proto dhcp scope link src 10.10.0.4 metric 1024
```


