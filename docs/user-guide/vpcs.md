# VPCs and Namespaces

## VPC

Virtual Private Cloud, similar to the public cloud VPC it provides an isolated private network for the resources with
support for multiple subnets each with user-provided VLANs and on-demand DHCP.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  ipv4Namespace: default # Limits to which subnets could be used by VPC to guarantee non-overlapping IPv4 ranges
  vlanNamespace: default # Limits to which switches VPC could be attached to guarantee non-overlapping VLANs
  subnets:
    default: # Each subnet is named, "default" subnet isn't required, but actively used by CLI
      dhcp:
        enable: true # On-demand DHCP server
        range: # Optionally, start/end range could be specified
          start: 10.10.1.10
      subnet: 10.10.1.0/24 # User-defined subnet from ipv4 namespace
      vlan: "1001" # User-defined VLAN from vlan namespace
    thrird-party-dhcp: # Another subnet
      dhcp:
        relay: 10.99.0.100/24 # Use third-party DHCP server (DHCP relay configuration), access to it could be enabled using StaticExternal connection
      subnet: "10.10.2.0/24"
      vlan: "1002"
    another-subnet: # Minimal configuration is just a name, subnet and VLAN
      subnet: 10.10.100.0/24
      vlan: "1100"
```

In case if you're using thirt-party DHCP server by configuring `spec.subnets.<subnet>.dhcp.relay` additional information
will be added to the DHCP packet it forwards to the DHCP server to make it possible to identify the VPC and subnet. The
information is added under the RelayAgentInfo option(82) on the DHCP packet. The relay sets two suboptions in the packet

* VirtualSubnetSelection -- (suboption 151) is populated with the VRF which uniquely idenitifies a VPC on the Hedgehog
  Fabric and will be in `VrfV<VPC-name>` format, e.g. `VrfVvpc-1` for VPC named `vpc-1` in the Fabric API
* CircuitID -- (suboption 1) identifies the VLAN which together with VRF (VPC) name maps to a specific VPC subnet

## VPCAttachment

Represents a specific VPC subnet assignment to the `Connection` object which means exact server port to a VPC binding.
It basically leads to the VPC being available on the specific server port(s) on a subnet VLAN.

VPC could be attached to a switch which is a part of the VLAN namespace used by the VPC.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: VPCAttachment
metadata:
  name: vpc-1-server-1--mclag--s5248-01--s5248-02
  namespace: default
spec:
  connection: server-1--mclag--s5248-01--s5248-02 # Connection name representing the server port(s)
  subnet: vpc-1/default # VPC subnet name
```

## VPCPeering

It enables VPC to VPC connectivity. There are tw o types of VPC peering:

* Local - peering is implemented on the same switches where VPCs are attached
* Remote - peering is implemented on the border/mixed leafs defined by the `SwitchGroup` object

VPC peering is only possible between VPCs attached to the same IPv4 namespace.

Local:

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: VPCPeering
metadata:
  name: vpc-1--vpc-3
  namespace: default
spec:
  permit: # Defines a pair of VPCs to peer
  - vpc-1: {} # meaning all subnets of two VPCs will be able to communicate to each other
    vpc-3: {} # more advanced filtering will be supported in future releases
```

Remote:

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: VPCPeering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  permit:
  - vpc-1: {}
    vpc-2: {}
  remote: border # indicates a switch group to implement the peering on
```

## IPv4Namespace

Defines non-overlapping VLAN ranges for attaching servers. Each switch belongs to a list of VLAN namespaces with
non-overlapping VLAN ranges.

```yaml
apiVersion: vpc.githedgehog.com/v1alpha2
kind: IPv4Namespace
metadata:
  name: default
  namespace: default
spec:
  subnets: # List of the subnets that VPCs can pick their subnets from
  - 10.10.0.0/16
```

## VLANNamespace

Defines non-overlapping IPv4 ranges for VPC subnets. Each VPC belongs to a specific IPv4 namespace.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: VLANNamespace
metadata:
  name: default
  namespace: default
spec:
  ranges: # List of VLAN ranges that VPCs can pick their subnet VLANs from
  - from: 1000
    to: 2999
```
