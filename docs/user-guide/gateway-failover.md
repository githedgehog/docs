# Gateway fail-over and redundancy
## Overview
When VPC *peerings* are configured to use a gateway, the latter is responsible for the delivery of the traffic exchanged between the VPCs on each side of the peering, fabric-wide. Failures in a gateway, its interconnects, or neighboring nodes can cause connectivity interruptions. Much as link protection is accomplished with interconnect redundancy, gateway failures are mitigated by deploying additional gateways. When more than one gateway is deployed in a Hedgehog Fabric, flexible fail-over strategies are possible to minimize service interruptions, as explained next.

!!! note
    Gateway "failures" do not necessarily refer to physical issues with the gateway device, its cabling or its software. Any condition that prevents a gateway from being reachable by fabric edges (such as multiple neighbor failures or their cabling) falls in this category. The fail-over strategy of the Hedgehog Fabric is designed to protect against those as well.

### Gateway groups
Gateway fail-over strategies build on the concept of *gateway groups*. A gateway group is a configurable, named set of gateways ranked by priority, such that the member gateway with highest priority is preferred over the rest, provided, of course, that it is operational. There is no limit on the number of groups that can be defined, and gateways can be members of as many groups as desired.
However:

!!! warning
    Currently, group sizes are limited to 10 members at the most. Such a limit may only affect in case you have more than 10 gateways deployed on the same fabric.

Declaring gateway groups is done by means of the `GatewayGroup` object. The following sample snippet shows the declaration of a group called **group-1**.

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
items:
- apiVersion: gateway.githedgehog.com/v1alpha1
  kind: GatewayGroup
  metadata:
    name: group-1
    namespace: default
  spec: {}
```

The set of gateways that belong to a *GatewayGroup* is not explicitly enumerated in the GatewayGroup. Instead, group membership is declared in the definition of the Gateway objects by referring to groups by their name and indicating a certain priority. The following snippet shows how **gateway-1** is a member of group **group-1** with priority 10.

!!! note inline end
    A `default` gateway group is implicitly created by the fabric and all gateways are members of it. Therefore, a gateway always belongs to at least one group even if no groups are explicitly declared.

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Gateway
metadata:
  name: gateway-1
  [..]
spec:
  asn: 65534
  groups:
    - name: group-1
      priority: 10
  [..]
```

!!! note
	The priority assigned to a gateway in a group has no significance in absolute terms. Configuring three gateways in the same group with priorities 300, 200 and 100 has the same effect as configuring them with priorities 51, 29 and 3.

Gateways implement services that are, in many cases, stateful. To correctly handle flows, the packets in the forward and reverse direction should be processed by the same gateway. The Hedgehog Fabric fail-over strategy is such that only one gateway handles a particular flow at any point in time. Gateway group priorities help to ensure that edge devices participating in a VPC peering select the same gateway. In future releases, it may be possible to balance the traffic of a single VPC peering over multiple gateways.

!!! note
    Since group membership priorities are specified in the gateways themselves (instead of the `GatewayGroup`s), with many groups and gateways, two or more gateways may end up being assigned the same priority in a given group. The fabric will not reject such a configuration: despite having the same priorities, only one of the gateways will be the preferred; the first when ordering the gateways within the group alphabetically by name. This tie-breaking criteria is implemented by all gateways so that only one gateway per group is selected consistently across the fabric.

## Using gateway groups: sample setups
### Minimal, default fail-over setup
The simplest fail-over setup consists of two gateways and a single gateway group. In this setup, one of the gateways is the preferred one and all of the traffic exchanged over all VPC peerings is serviced by that gateway. In the event that it fails, the other gateway takes over. This strategy is commonly called Active-Backup in many redundant systems.

!!! note
    Since there always exists a `default` gateway group (containing all of the gateways), this Active-Backup behavior is (for any number of gateways) the default when no additional configuration is provided.

### Customizing fail-over setups: traffic mapping to gateway groups
With the previous setup, one of the two gateways remains idle, which can be sub-optimal and under-utilize resources. In order to overcome this, VPC peerings can be specified with a `GatewayGroup` to indicate the name of the gateway group that should serve the traffic for that peering, as shown in the following snippet.

!!! info inline end
    A VPC peering always has a single `GatewayGroup`: if not explicitly set, the system automatically assigns it the `default` group. This is the reason why the behavior without any configuration is Active-Backup.

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    gatewayGroup: group-1
    vpc-1:
      expose: [..]
    vpc-2:
      expose: [..]
```

We refer to this as "_mapping_ the peering" to the gateway group.

The possibility of creating multiple gateway groups (with distinct gateways and priorities), and of mapping VPC peerings individually to them provides greater flexibility and advantages. For instance, consider a fabric with 3 gateways deployed G1, G2 and G3, and take the case of a VPC _vpc-1_ that peers with N other VPCs, _vpc-n_ n=2..N. Three groups could be defined, each containing the 3 gateways but with distinct priorities such that a distinct gateway would be the preferred in each group. By mapping the N-1 peerings of _vpc-1_ to the 3 groups, the traffic exchanged by _vpc-1_ would use distinct gateways to reach each of the VPCs it peered with, while guaranteeing that each flow exchanged be handled by a single gateway. By mapping the peerings the other VPCs may have, this type of configuration would allow balancing all of the load among the three gateways and, in turn, the links and fabric nodes these were connected to. Plus, in the event of a failure, only the peerings mapped to the failed gateway may be momentarily affected and be re-routed.

!!! note
	One consequence of mapping a peering to a non-default `GatewayGroup` is that any gateway that is not a member of that group will not be used to serve the traffic for that peering, even if all gateways in that group become unavailable.

!!! tip
	Gateway groups and the peering mappings can be handy for other purposes. For instance, removing a gateway from a group allows pulling the traffic of all peerings mapped to that group out of that gateway. Or, by adjusting member priorities, traffic can be re-mapped without changing the peering mappings to groups.

## Fail-over under the hood and recommendations
The gateway fail-over strategy in the Hedgehog Fabric is implemented in a distributed manner. Gateways announce VPC peering prefixes with the specified priorities, while edge nodes (such as leaf switches) select the gateway that handles each packet based on the destination and the priorities. If a VPC peering refers to a group that has K members, the edge devices participating in the VPC will have K BGP routes (one per gateway) for each of the peering destinations. However, only one of those routes will be active at any point in time; the one advertised by (and pointing to) the preferred active gateway.

Because edge devices perform the fail-over when a gateway ceases to be reachable, downtime in case of failure depends on how quickly those devices reckon the anomaly. To minimize the detection time (and the volume of traffic blackholed), it is recommended to enable BFD on gateway links in order to expedite the propagation of failures.

!!! note "Takeaways and configuration summary"
    Redundancy works out of the box in an Active-Backup fashion. To customize the behavior, you can:

    1. Declare gateway groups (`GatewayGroup` objects) depending on the number of gateways available.
    2. Assign gateways to those groups, with suitable priorities. The recommendation is to assign a high priority to each gateway in at least one of the groups so that load is shared evenly among all gateways.
    3. Map VPC peerings to the groups defined.
    4. Enable BFD on gateway links.
