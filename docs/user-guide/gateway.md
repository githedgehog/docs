# Gateway

Not all network services can be provided by the fabric itself due to limitations with modern switch hardware and software.
The Gateway is designed to provide these more sophisticated network services, such as NAT, PAT, firewalling, and others.
The tradeoff is that while simple [VPC Peerings](vpcs.md#vpcpeering) offer the full cut-through bandwidth of the fabric, gateway services are limited by the traffic handling capability of the gateway nodes.


## Gateway Nodes and Fabric Connectivity

Gateway nodes are connected to the fabric by a set of physical connectionsthat are modeled via Connection objects.
See the section on [Gateway Connections](connections.md#gateway-connections) for connection requirements and example configuration.

When a Gateway Peering is used to connect two VPCs or externals, the appropriate gateway nodes will attract traffic to themselves by advertising the appropriate routes to the fabric.
In turn, the fabric will use these routes to steer traffic to the gateway so that it can apply the configured peering policy.

Gateway nodes use BGP to advertise routes to the fabric, and the gateway will get its own ASN so it is possible to easily identify gateway advertised routes in the fabric.

## Gateway Peering

Just as [VPC Peerings](vpcs.md#vpcpeering) provide VPC to VPC connectivity by way of the switches in the fabric, gateway peerings provide connectivity via the gateway nodes.
Gateway services can be inserted between any pair of VPCs or externals using a Gateway Peering.
Each peering can be configured to provide the necessary services for traffic that uses that peering.

### Simple Gateway Peering Between VPCs

```{.yaml .annotate linenums="1" title="gw-peer.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
      expose:
        - ips:
          - cidr: 10.0.0.0/24 # Expose all IP address in the 10.0.0.0/24 CIDR block to vpc-2
    vpc-2:
      expose:
        - ips:
          - cidr: 192.168.0.0/16 # Expose all IP addresses in the 192.168.0.0/16 CIDR block to vpc-1
```

A simple peering with no services deployed between the VPCs. This traffic will
transit the gateway node(s).

### Gateway Peering with stateless NAT

```{.yaml .annotate linenums="1" title="sl-gw-peer.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--sl-nat--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
      expose:
        - ips:
          - cidr: 10.0.1.0/24 # Expose all IP address in the 10.0.1.0/24 CIDR block to vpc-2
          as:
          - cidr: 10.11.11.0/24
        - ips:
          - cidr: 10.0.2.3/32 # Expose the single IP Statless NAT mapping to vpc-2
          as:
          - cidr: 10.11.22.3/32
    vpc-2:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
          as:
          - cidr: 10.22.22.0/25
          - cidr: 10.22.22.128/25


```

Stateless NAT translates source and destination IP addresses for all packets that traverse
the peering, but it does not maintain any flow state for the connection. A 
one-to-one mapping is established between the addresses exposed in the CIDRs for
`ips` and the addresses to use represented by the CIDRs in
`as:` each address from the first group is consistently mapped to a single
address from the second group. Therefore, the total number of addresses covered
by the CIDRs YAML array entries from `ips` must be equal to the total number of
addresses covered by the CIDRs from `as`.

### Gateway Peering with stateful NAT

```{.yaml .annotate linenums="1" title="gw-sf-nat-peer.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--sf-nat--vpc-2
  namespace: default
spec:
  peering:
    vpc-01:
      expose:
        # Allow 10.0.0.0/24 addresses to talk to vpc-2
        # Because of stateful NAT, traffic from vpc-2 to vpc-1 is only allowed if there is
        # a flow table entry created by a traffic initiated from vpc-1 to vpc-2.
        - ips:
          - cidr: 10.0.0.0/24
          as:
          - cidr: 10.0.1.0/31  # but, NAT those addresses using the addresses in 10.0.1.0/31
          nat:  # Contains the nat configuration
            stateful:  # Make NAT stateful, connections initiated from vpc-1 to vpc-2 will be added to the flow table
              idleTimeout: 5m # Timeout connections after 5 minutes of inactivity (no packets received)
    vpc-2:
      expose:
        # Allows traffic from vpc-1 to vpc-2 on these addresses.
        # Connections must be initiated from vpc-1 to vpc-2 due to flow tracking.
        - ips:
          - cidr: 192.168.0.0/16
        # Currently, only one VPC of an expose block can use NAT when using stateful NAT.
        # This restriction will be lifted in a future release.
```

Stateful NAT uses a flow table to track established connections.
When traffic is initiated from `vpc-1` to `vpc-2`, the flow table is updated 
with the connection details. In the return direction (from `vpc-2` to `vpc-1`
in the example below), the flow table is consulted to determine if the packet
is part of an established connection. If it is, the packet is allowed to pass 
through the peering. If it is not, the packet is dropped.
This behavior allows use of stateful NAT as a simple firewall.

### Gateway Peering with NAT for External Connections

TODO: Please write this section once external gateway peering support is complete.
