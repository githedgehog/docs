# Gateway

The Gateway adds advanced network service capabilities to the fabric,
complementing its fast, scalable connectivity. The fabric delivers efficient,
cut-through transport between workloads, while the Gateway provides additional
capabilities such as NAT, PAT, and firewalling. Simple [VPC Peerings](vpcs.md#vpcpeering) use the
full bandwidth of the fabric, whereas traffic using Gateway services is
handled through the Gateway nodes, which determine the available throughput.
Together, they offer both high-performance connectivity and rich network services.

## Gateway Nodes and Fabric Connectivity

Gateway nodes are connected to the fabric by a set of physical connections that are modeled via Connection objects.
See the section on [Gateway Connections](connections.md#gateway-connections) for connection requirements and example configuration.

When a Gateway Peering is used to connect two VPCs or externals, the gateway nodes attract traffic to themselves by advertising the appropriate routes to the fabric.
In turn, the fabric uses these routes to steer traffic to the gateway so that
the gateway can apply the configured peering policy.

Gateway nodes use BGP to advertise routes to the fabric, and the gateway gets its own ASN so it is possible to easily identify gateway-advertised routes in the fabric.

```mermaid
graph TD

%% Style definitions
classDef gateway fill:#FFF2CC,stroke:#CC9900,stroke-width:1px,color:#000
classDef spine   fill:#F8CECC,stroke:#B85450,stroke-width:1px,color:#000
classDef leaf    fill:#DAE8FC,stroke:#6C8EBF,stroke-width:1px,color:#000
classDef server  fill:#D5E8D4,stroke:#82B366,stroke-width:1px,color:#000
classDef hidden fill:none,stroke:none
classDef legendBox fill:none,stroke:none,color:#000

%% Network diagram

Gateway_01["Gateway"]

subgraph Spines[" "]
    direction LR
    Spine_01["Spine-1"]
    Spine_02["Spine-2"]
end

subgraph Leaves[" "]
    direction LR
    Leaf_01["Leaf-1"]
    Leaf_02["Leaf-2"]
    Leaf_03["Leaf-3"]
end

subgraph Servers[" "]
    direction TB
    Server_01["Server-1"]
    Server_02["Server-2"]
    Server_03["Server-3"]
    Server_04["Server-4"]
    Server_05["Server-5"]
    Server_06["Server-6"]
end

%% Connections

%% Gateway_01 -> Spines
Gateway_01 --- Spine_01
Gateway_01 --- Spine_02

Spine_01 --- Leaf_01
Spine_01 --- Leaf_02
Spine_01 --- Leaf_03
Spine_02 --- Leaf_01
Spine_02 --- Leaf_02
Spine_02 --- Leaf_03

%% Leaves -> Servers
Leaf_01 --- Server_01
Leaf_01 --- Server_02
Leaf_02 --- Server_03
Leaf_02 --- Server_04
Leaf_03 --- Server_05
Leaf_03 --- Server_06

subgraph Legend["Network Connection Types"]
    direction LR
    %% Create invisible nodes for the start and end of each line
    L1(( )) --- |"Gateway Links"| L2(( ))
    L7(( )) --- |"Fabric Links"| L8(( ))
    L9(( )) --- |"Server Links"| L10(( ))
end

class Gateway_01 gateway
class Spine_01,Spine_02 spine
class Leaf_01,Leaf_02,Leaf_03 leaf
class Server_06,Server_05,Server_04,Server_03,Server_02,Server_01 server
class L1,L2,L7,L8,L9,L10 hidden
class Legend legendBox
linkStyle default stroke:#666,stroke-width:2px
linkStyle 0,1 stroke:#CC9900,stroke-width:2px
linkStyle 2,3,4,5,6,7 stroke:#CC3333,stroke-width:2px
linkStyle 8,9,10,11,12,13 stroke:#6C8EBF,stroke-width:2px
linkStyle 14 stroke:#CC9900,stroke-width:2px
linkStyle 15 stroke:#CC3333,stroke-width:2px
linkStyle 16 stroke:#6C8EBF,stroke-width:2px

%% Make subgraph containers invisible
style Spines fill:none,stroke:none
style Leaves fill:none,stroke:none
style Servers fill:none,stroke:none
```

## Gateway Peering

Just as [VPC Peerings](vpcs.md#vpcpeering) provide VPC-to-VPC connectivity by way of the switches in the fabric, gateway peerings provide connectivity via the gateway nodes.
Gateway services can be inserted between a pair of VPCs or a VPC and an external using a Gateway Peering.
Each peering can be configured to provide the necessary services for traffic
that uses that peering. Peering the same entities via gateway and fabric
at the same time results in undefined behaviour. If two entities (VPCs or externals) are already
peered via the fabric, delete this peering first, then peer them via the
gateway.

### Simple Gateway Peering Between VPCs

A simple peering with no services deployed between the VPCs. This traffic will
transit the gateway node(s).

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

Note that multiple VPCs cannot expose overlapping prefixes to a given VPC. For
example, if `vpc-1` and `vpc-3` are both peered with `vpc-2`, and `vpc-1`
exposes subnet `10.1.1.0/24` to `vpc-2`, then `vpc-3` cannot expose overlapping
prefix `10.1.0.0/16` to `vpc-2`. There is one exception to this rule: exposed
prefixes can overlap with an expose block marked as `default`, see section on
[peering for external connections](#gateway-peering-for-external-connections)
for details.

### Gateway Peering with Stateless NAT

Stateless NAT translates source and/or destination IP addresses for all packets that traverse
the peering, but it does not maintain any flow state for the connection. A
one-to-one mapping is established between the addresses exposed in the CIDRs for
`ips` and the addresses to use represented by the CIDRs in
`as`: each address from the first group is consistently mapped to a single
address from the second group. Therefore, the total number of addresses covered
by the CIDRs YAML array entries from `ips` must be equal to the total number of
addresses covered by the CIDRs from `as`.

```{.yaml .annotate linenums="1" title="gw-sl-nat-peer.yaml"}
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
          - cidr: 10.0.1.0/24 # IP addresses in the 10.0.1.0/24 block will be exposed ...
          as:
          - cidr: 10.11.11.0/24 # as IP addresses in the 10.11.11.0/24 block.
        - ips:
          - cidr: 10.0.2.3/32 # This single IP address will be reachable...
          as:
          - cidr: 10.11.22.3/32 # as this IP address in vpc-2.
    vpc-2:
      expose:
        - ips:
          - cidr: 10.0.2.0/24 # A /24 can be split into two ranges
          as:
          - cidr: 10.22.22.0/25 # and exposed back to vpc-1.
          - cidr: 10.22.22.128/25
```

### Gateway Peering with Stateful Source NAT

Stateful source NAT uses a flow table to track established connections.
When traffic is initiated from `vpc-1` to `vpc-2`, the flow table is updated
with the connection details. In the return direction (from `vpc-2` to `vpc-1`
in the following example), the flow table is consulted to determine if the packet
is part of an established connection. If it is, the packet is allowed to pass
through the peering. If it is not, the packet is dropped.
This behavior allows use of stateful NAT as a simple firewall.

```{.yaml .annotate linenums="1" title="gw-sf-nat-peer.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--sf-nat--vpc-2
  namespace: default
spec:
  peering:
    vpc-1:
      expose:
        # Allow 10.0.0.0/24 addresses to talk to vpc-2
        # Because of stateful NAT, traffic from vpc-2 to vpc-1 is only allowed if there is
        # a flow table entry created by a traffic initiated from vpc-1 to vpc-2.
        - ips:
          - cidr: 10.0.0.0/24
          as:
          - cidr: 10.0.1.0/31  # but, NAT those addresses using the addresses in 10.0.1.0/31
          nat:  # Contains the NAT configuration
          # Make NAT stateful, connections initiated from vpc-1 to vpc-2 will be added to the flow table.
          # An entry for the reverse direction will be added too, so that the receiving endpoint in vpc-2 can reply.
            stateful:
              idleTimeout: 5m # Timeout connections after 5 minutes of inactivity (no packets received)
    vpc-2:
      expose:
        # Allows traffic from vpc-1 to vpc-2 on these addresses.
        # Connections must be initiated from vpc-1 to vpc-2 due to flow tracking.
        - ips:
          - cidr: 192.168.0.0/16
        # Currently, only one VPC of a peering can use stateful NAT.
        # This restriction will be lifted in a future release.
```

### Gateway Peering with Port Address Translation

Stateless NAT can also work with port ranges, a feature known as Port Address
Translation (PAT).

#### Stateless PAT

For stateless translation, ports or port ranges can be specified for the IP
prefix to translate (`ips`) as well as for the target prefixes (`as`).

- Specifying ports or port ranges for a prefix in `ips` means that only packets
  whose source L4 ports are in the list will be translated.
- Specifying ports or port ranges for a prefix in `as` means that ports will be
  translated to ports within the resulting list of ports.

##### Example

The following YAML fragment is an example with port translation configured on
`vpc-1`'s side:

```{.yaml .annotate linenums="1" title="gw-sl-pat-peer.yaml"}
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
          - cidr: 10.0.1.0/24
            ports: 2001-3000
          as:
          - cidr: 192.168.11.0/24
            ports: 4999,5002-6000
    vpc-2:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
```

In this example, packets emitted from `vpc-1` to `vpc-2` with a source IP
address in `10.0.1.0/24` _and_ a TCP or UDP source port between 2001 and 3000
(included), are translated with a new source IP in CIDR `192.168.11.0/24` and a
source port being either `4999` or between `5002` and `6000` (included),
whereas the destination IP and port are unchanged. Packets emitted in the other
direction, from `vpc-2` to `vpc-1`, have their destination address and L4 port
translated back to the initial prefix and port range.

For example, once this peering has been created, if `vpc-1` sends the following
TCP packet:

- source IP: `10.0.1.2`
- source TCP port: `2032`
- destination IP: `10.0.2.2`
- destination TCP port: `8080`

then on reception, the gateway statelessly translates it to the following,
before forwarding it to `vpc-2`:

- source IP: `192.168.11.2` (or any other address from `192.168.11.0/24`,
  depending on the internal mapping algorithm)
- source TCP port: `5784` (or any other port from `5002-6000`, or `4999`,
  depending on the internal mapping algorithm)
- destination IP: `10.0.2.2` - unchanged
- destination TCP port: `8080` - unchanged

We could use ports and port ranges on `vpc-2`'s side as well, in a similar way.

The field `ports` accepts a comma-separated list of ports and port ranges. Port
ranges are specified with the lower and higher bounds for the range
(inclusive), separated with a dash. Spaces are not allowed within the string
for ports and port ranges.

##### Size constraints

Like for stateless NAT, a one-to-one mapping is established between elements to
translate (`ips`) and target addresses and ports (`as`). As a consequence, the
number of addresses covered by the IP prefixes, multiplied by the number of
ports in the relative port ranges (if any), must be equal between `ips` and
`as`. For example, CIDR `10.0.1.0/24` (256 IP addresses) with port range
`2000-2099` (100 ports) covers 25,600 combinations.

If a CIDR has no associated ports or port ranges, the full space of available
ports (65536 ports) is used, just like in the case of NAT.

##### Limitations

Note that when PAT is set up for a given CIDR prefix, packets addressed to IPs
in this prefix but not matching the ports or port ranges will be dropped,
because the gateway may not be able to determine their destination VPC. In
particular, with PAT set for a given prefix, **ICMP and all non-TCP or non-UDP
overlay traffic will be dropped** if trying to use this prefix to communicate
between the two VPCs associated with the peering.

Configuring different port ranges for TCP and UDP, individually, is not
currently supported.

#### Stateful PAT

Specifying port ranges for a prefix exposed with stateful NAT is not currently
supported.

### Gateway Peering for External Connections

The following YAML listings show how to create an external and expose a default
route to the `10.50.2.0/24` subnet inside of `vpc-02`. In this example, the
name of the external is `example-ext`. Assuming this external represents the
WAN, this configuration allows hosts inside of the `10.50.2.0/24` subnet to
reach the WAN.

Here is the YAML fragment for creating the external:

```{.yaml .annotate linenums="1" title="example-external.yaml"}
apiVersion: vpc.githedgehog.com/v1beta1
kind: External
metadata:
  name: example-ext
  namespace: default
spec:
  inboundCommunity: 65102:5001
  ipv4Namespace: default
  outboundCommunity: 5001:65102
```

Once the external is created, the gateway can be used to create a peering
between the external and a VPC. The following YAML is an example of this
configuration:

```{.yaml .annotate linenums="1" title="gw-peer-external.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-02--example-ext
spec:
  peering:
    ext.example-ext: # NOTE the name of the external is prefixed with "ext."
      expose:
      - default: true # Fallback destination when no other expose matches
    vpc-02:
      expose:
      - ips:
        - cidr: 10.50.2.0/24
```

Note that the name of the external is prefixed with `ext.`: this is a
requirement.

Also, note how the external uses `default: true` instead of specifying the root
IPv4 prefix `0.0.0.0/0`. An `expose` block marked as `default: true` serves as
a default destination for all addresses _that do not otherwise match any of the
other prefixes exposed to the VPC_, whether or not these prefixes are from the
same peering. In our example, if `vpc-02` is additionally peered with `vpc-03`
which exposes `10.50.3.0/24`, all packets from `vpc-02` towards this subnet are
sent to `vpc-03`, and packets addressed to all other subnets from the IPv4
space are sent to the external `example-ext`.

For any given VPC, at most one remote `expose` block, among all peerings for
this VPC, can act as a `default` destination.
