# Gateway

## Gateway Connections

TODO: Write me

## Gateway Peering

[Vpc Peerings](vpcs.md#vpcpeering) provide VPC to VPC connectivity by way of the switches in the fabric.
These peerings use route leaking inside the switch fabric to allow on VPC to communicate with another VPC.
While this works well for many types of connections, especially those that need the full cut-through bandwidth of the fabric, the switch fabric is limited in the functionality in can provide with regard to the peering.
For example, any peering that requires network address translation (NAT), or firewalling, and other functionality beyond the capabilities of the switch fabric cannot use a standard VPC peering.

For such cases, Hedgehog provides a Gateway Peering feature in fabrics that have attached gateways.
A gateway peering provides connectivity between VPCs (or externals) but causes the traffic to flow through a gateway node which can provide advanced services such as NAT and firewall.
The downside is that the peering is limited in bandwidth to the capacity of the gateway node(s) instead of the full cut-through bandwidth of the fabric.

### Simple Gateway Peering Between VPCs

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
      - expose:
        - ips: 10.0.0.0/24 # Expose all IP address in the 10.0.0.0/24 CIDR block to vpc-2
    vpc-2:
      - expose:
        - ips: 192.168.0.0/16 # Expose all IP addresses in the 192.168.0.0/16 CIDR block to vpc-1
```

### Gateway Peering with stateless NAT

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
     - expose:
        - ips: 10.0.0.0/24 # Expose all IP address in the 10.0.0.0/24 CIDR block to vpc-2
          as: 10.0.1.0/24  # 10.0.0.0/24 addresses are seen as to 10.0.1.0/24 addresses for vpc-2
    vpc-2:
     - expose:
        - ips: 192.168.0.0/16 # Expose all IP addresses in the 192.168.0.0/16 CIDR block to vpc-1
          as: 192.168.1.0/24  # 192.168.0.0/16 addresses are seen as to 192.168.1.0/24 addresses for vpc-1
```

Stateless NAT blindly translates source and destination IP addresses for all packets that traverse
the peering, but it does not maintain any connection or flow state for the connection.

### Gateway Peering with stateful NAT

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
     - expose:
        # Allow 10.0.0.0/24 addresses to talk to vpc-2
        # Because of stateful NAT, traffic from vpc-2 to vpc-1 is only allowed if there is
        # a flow table entry created by a traffic initiated from vpc-1 to vpc-2.
        - ips: 10.0.0.0/24
          as: 10.0.1.0/32  # but, NAT those addresses using the addresses in 10.0.1.0/31
          nat:  # Contains the nat configuration
            stateful:  # Make NAT stateful, connections initiated from vpc-1 to vpc-2 will be added to the flow table
              idleTimeout: 5m # Timeout connections after 5 minutes of inactivity (no packets received)
    vpc-2:
      - expose:
        # Allows traffic from vpc-1 to vpc-2 on these addresses.
        # Connections must be initiated from vpc-1 to vpc-2 due to flow tracking.
        - ips: 192.168.0.0/16
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
