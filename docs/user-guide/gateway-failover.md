# Gateway fail-over and redundancy
## Overview
When VPC *peerings* are configured to use a gateway, the latter is responsible for the delivery of the traffic exchanged between the VPCs on each side of the peering, fabric-wide. Failures in a gateway, its interconnects, or neighboring nodes can cause connectivity interruptions. Much as link protection is accomplished with interconnect redundancy, gateway failures are mitigated by deploying additional gateways. When more than one gateway is present in a HedgeHog Fabric, flexible fail-over strategies are possible to minimize service interruptions, as explained next.

!!! note
    When we talk about gateway "failures", we do not necessarily refer to physical issues with the gateway device, its cabling or its software. Any condition that prevents a gateway from being reachable  by fabric edges (such as multiple neighbor failures or their cabling) falls in this category. The fail-over strategy of the Hedgehog Fabric is designed to protect against those as well.

### Gateway groups
Gateway fail-over strategies build on the concept of `gateway groups`. A gateway group is a configurable, named set of gateways ranked by priority, such that the member gateway with highest priority is preferred over the rest, provided, of course, that it is operational. A gateway can be a member of one or more gateway groups, and there is no limit on the number of groups that can be defined or their sizes (number of members).

!!! note
	All gateways in a fabric are members of, at least, one *default* group that always exists.

Declaring gateway groups is done by means of the *GatewayGroup* object. The following sample snippet shows the declaration of a group called **group-1**.

```yaml
apiVersion: v1
items:
- apiVersion: gateway.githedgehog.com/v1alpha1
  kind: GatewayGroup
  metadata:
    name: group-1
    namespace: default
  spec: {}
```

The set of gateways that belong to a *GatewayGroup* is not explicitly enumerated in the GatewayGroup. Instead, group membership is declared in the definition of the Gateway objects by referring to groups by their name and indicating a certain priority. The following snippet shows how **gateway-1** is a member of group **group-1** with priority 10.

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Gateway
metadata:
  name: gateway-1
  [..]
spec:
  asn: 65534
  groups:
    - name: default # all gateways belong to this group
    - name: group-1 # gateway-1 is now member of this group
      priority: 10
  [..]
```

!!! note
    A gateway can be a member of as many groups as desired.

!!! note
	The value of the priority specified by a gateway within a group has no significance in absolute terms. For instance, configuring two gateways G1 and G2 as members of the same group with priorities 200 and 100 has the same effect as configuring them with priorities 29 and 3.

The priorities within a group not only allow indicating a preference, but also making sure that VPC peering traffic can be correctly processed: since gateways implement services that are stateful, only one gateway within a group should service a flow at a given point. This restriction may be lifted in the future.

!!! notice
    Since the specification of group membership priorities is distributed across each of the gateways, with many groups and gateways, two or more gateways may be assigned the same priority in a given group. The system will not complain with such a configuration: despite having the same priorities, only one gateway will be the preferred; the one with the highest VTEP IP. This tie-breaking logic is implemented by all gateways so that a single gateway per group is selected consistently fabric-wide.

## Using gateway groups: sample setups
### Minimal, default fail-over setup
The simplest fail-over setup consists of two gateways and a single gateway group. In this setup, one of the gateways is the preferred one and all of the traffic exchanged over all VPC peerings is serviced by that gateway. In the event that it fails, the other gateway takes over. This strategy is commonly called Active-Backup in many redundant systems.

!!! note
    Since there always exists a *default* gateway group (containing all of the gateways), this Active-backup behavior is (for any number of gateways) the default when no additional configuration is provided.

### Customizing fail-over setups: traffic mapping to gateway groups
With the previous setup, one of the two gateways remains idle, which can be sub-optimal and under-utilize resources. In order to overcome this, VPC peerings can be specified a **gatewayGroup** to indicate the name of the desired gateway group to service the traffic for that peering, as shown by the snippet below.

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Peering
metadata:
  name: vpc-1--vpc-2
  namespace: default
spec:
  peering:
    gatewayGroup: group-1  # Gateway group to service this peering
    vpc-1:
      expose: [..]
    vpc-2:
      expose: [..]
```

We refer to this as _mapping_ the peering to the gateway group.

!!! note
    A VPC peering always has a gatewayGroup: if not explicitly set, the system automatically assigns it the the *default* group. This is why without any configuration, the default behavior is Active-Backup.

!!! note
	A consequence of mapping a peering to a non-default gatewayGroup is that any gateway that is not a member of the gatewayGroup will not be used to serve the traffic for that peering.

The possibility of creating multiple gateway groups and of referring to them on a per VPC peering basis provides greater flexibility and advantages. For instance, suppose that there are 3 gateways (G1, G2 and G3) and consider a single VPC, _vpc-1_ that peers with VPCs _vpc-n_ for n:2..N. Three groups could be defined such that each of the gateways would be the preferred one in one of them. By mapping the N-1 peerings to distinct groups, the traffic exchanged by _vpc-1_ will use a distinct gateways depending on the peering it belongs to.
This allows sharing the load among the three gateways, preserving the condition that a single flow is served by only one of them. Under high traffic loads, this configuration can lead to a more even utilization of fabric nodes and links. In the event of a failure, only the peerings mapped to the failed gateway can be momentarily affected.

!!! bonus
	Gateway groups and the peering mappings can be handy for other purposes. For instance, removing a gateway from a group allows gracefully pulling the traffic for all the peerings mapped to that group out of that gateway. Or, by adjusting member priorities, traffic can be re-routed without changing the peering mappings to groups.

## Fail-over behind the scenes and recommendations
The gateway fail-over strategy in the Hedgehog Fabric is implemented in a distributed manner. Gateways announce VPC peering prefixes with the specified priorities, while edge nodes (e.g. leaf switches)  select the gateway that will handle each packet based on those. If a VPC peering refers to a group that has K members, the edge devices participating in the VPC will have K BGP routes (one per gateway) for each of the peering destinations. However, only one of those routes will be active at any point in time; the one advertised by (and pointing to) the preferred active gateway.

Because edge devices perform the fail-over when a preferred gateway ceases to be reachable, downtime on failure depends on how fast edge devices reckon the anomaly. To expedite the failure detection and minimize the volume of traffic blackholed, it is recommended to enable BFD on all gateway links.

!!! Takeaways
    Setting up gateway redundancy generally requires:

    1. declaring gateway groups (**GatewayGroup** objects) depending on the number of gateways available.
    2. Assigning gateways to the groups, with suitable priorities. For load sharing purposes, the recommendation is to assign a high priority to each gateway in at least one of the groups.
    3. Mapping the VPC peerings to the groups defined.
    4. Enabling BFD on gateway links.
