# Gateway

## Gateway Connections

The Gateway provides network services like: peering, NAT, and firewall for
traffic entering and exiting the fabric, as well as traffic between VPCs. The
Gateway is connected to the fabric spines, a minimum of two connections is
required. The Gateway has its own ASN to use in the BGP routing protocol.
Connections between the fabric and the outside world should use the Gateway.
For example a data center WAN connection should meet the fabric at the Gateway.


## Gateway Peering

[VPC Peerings](vpcs.md#vpcpeering) provide VPC to VPC connectivity by way of the switches in the fabric.
These peerings use route leaking inside the switch fabric to allow on VPC to communicate with another VPC.
While this works well for many types of connections, especially those that need the full cut-through bandwidth of the fabric, the switch fabric is limited in the functionality in can provide with regard to the peering.
For example, any peering that requires network address translation (NAT), or firewalling, and other functionality beyond the capabilities of the switch fabric cannot use a standard VPC peering.

For such cases, Hedgehog provides a Gateway Peering feature in fabrics that have attached gateways.
A Gateway Peering provides connectivity between VPCs (or externals) but causes the traffic to flow through a gateway node which can provide advanced services such as NAT and firewall.
The downside is that the peering is limited in bandwidth to the capacity of the gateway node(s) instead of the full cut-through bandwidth of the fabric.


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
transit the gateway node.

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
          - cidr: 10.11.11.0/24 # Cr
    vpc-2:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
          as:
          - cidr: 10.22.22.0/24

```

Stateless NAT blindly translates source and destination IP addresses for all packets that traverse
the peering, but it does not maintain any connection or flow state for the
connection. The mapping is one for one, to reach `10.0.1.3` on vpc-1 from
vpc-2, use `10.11.11.3` as the destination address. The cidr for IP addresses
must be equal.


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
          - cidr: 10.0.1.0/32  # but, NAT those addresses using the addresses in 10.0.1.0/31
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
When traffic is initiated from vpc-1 to vpc-2, the flow table is updated with the connection details.
In the return direction (from `vpc-2` to `vpc-1` in the example below), the flow table is consulted to determine if the packet is part of an established connection.
If it is, the packet is allowed to pass through the peering.  If it is not, the packet is dropped.
This behavior allows use of stateful NAT as a simple firewall.

### Gateway Peering with NAT for External Connections

TODO: Please write this section once external gateway peering support is complete.
