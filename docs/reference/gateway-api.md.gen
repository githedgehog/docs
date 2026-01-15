# API Reference

## Packages
- [gateway.githedgehog.com/v1alpha1](#gatewaygithedgehogcomv1alpha1)
- [gwint.githedgehog.com/v1alpha1](#gwintgithedgehogcomv1alpha1)


## gateway.githedgehog.com/v1alpha1

Package v1alpha1 contains API Schema definitions for the gateway v1alpha1 API group.

### Resource Types
- [Gateway](#gateway)
- [GatewayGroup](#gatewaygroup)
- [Peering](#peering)
- [VPCInfo](#vpcinfo)



#### Gateway



Gateway is the Schema for the gateways API.





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `gateway.githedgehog.com/v1alpha1` | | |
| `kind` _string_ | `Gateway` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `spec` _[GatewaySpec](#gatewayspec)_ |  |  |  |
| `status` _[GatewayStatus](#gatewaystatus)_ |  |  |  |


#### GatewayBGPNeighbor



GatewayBGPNeighbor defines the configuration for a BGP neighbor



_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `source` _string_ | Source is the source interface for the BGP neighbor configuration |  |  |
| `ip` _string_ | IP is the IP address of the BGP neighbor |  |  |
| `asn` _integer_ | ASN is the remote ASN of the BGP neighbor |  |  |


#### GatewayGroup



GatewayGroup is the Schema for the gatewaygroups API





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `gateway.githedgehog.com/v1alpha1` | | |
| `kind` _string_ | `GatewayGroup` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `spec` _[GatewayGroupSpec](#gatewaygroupspec)_ |  |  |  |
| `status` _[GatewayGroupStatus](#gatewaygroupstatus)_ |  |  |  |


#### GatewayGroupMembership







_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `name` _string_ | Name is the name of the group to which the gateway belongs |  |  |
| `priority` _integer_ | Priority is the priority of the gateway within the group |  |  |


#### GatewayGroupSpec



GatewayGroupSpec defines the desired state of GatewayGroup



_Appears in:_
- [GatewayGroup](#gatewaygroup)



#### GatewayGroupStatus



GatewayGroupStatus defines the observed state of GatewayGroup.



_Appears in:_
- [GatewayGroup](#gatewaygroup)



#### GatewayInterface



GatewayInterface defines the configuration for a gateway interface



_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `pci` _string_ | PCI address of the interface (required for DPDK driver), e.g. 0000:00:01.0 |  |  |
| `kernel` _string_ | Kernel is the kernel name of the interface to use (required for kernel driver), e.g. enp2s1 |  |  |
| `ips` _string array_ | IPs is the list of IP address to assign to the interface |  |  |
| `mtu` _integer_ | MTU for the interface |  |  |


#### GatewayLogLevel

_Underlying type:_ _string_





_Appears in:_
- [GatewayLogs](#gatewaylogs)

| Field | Description |
| --- | --- |
| `off` |  |
| `error` |  |
| `warning` |  |
| `info` |  |
| `debug` |  |
| `trace` |  |


#### GatewayLogs



GatewayLogs defines the configuration for logging levels



_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `default` _[GatewayLogLevel](#gatewayloglevel)_ |  |  |  |
| `tags` _object (keys:string, values:[GatewayLogLevel](#gatewayloglevel))_ |  |  |  |


#### GatewayProfiling







_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `enabled` _boolean_ |  |  |  |


#### GatewaySpec



GatewaySpec defines the desired state of Gateway.



_Appears in:_
- [Gateway](#gateway)
- [GatewayAgentSpec](#gatewayagentspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `protocolIP` _string_ | ProtocolIP is used as a loopback IP and BGP Router ID |  |  |
| `vtepIP` _string_ | VTEP IP to be used by the gateway |  |  |
| `vtepMAC` _string_ | VTEP MAC address to be used by the gateway |  |  |
| `asn` _integer_ | ASN is the ASN of the gateway |  |  |
| `vtepMTU` _integer_ | VTEPMTU is the MTU for the VTEP interface |  |  |
| `interfaces` _object (keys:string, values:[GatewayInterface](#gatewayinterface))_ | Interfaces is a map of interface names to their configurations |  |  |
| `neighbors` _[GatewayBGPNeighbor](#gatewaybgpneighbor) array_ | Neighbors is a list of BGP neighbors |  |  |
| `logs` _[GatewayLogs](#gatewaylogs)_ | Logs defines the configuration for logging levels |  |  |
| `profiling` _[GatewayProfiling](#gatewayprofiling)_ | Profiling defines the configuration for profiling |  |  |
| `workers` _integer_ | Workers defines the number of worker threads to use for dataplane |  |  |
| `groups` _[GatewayGroupMembership](#gatewaygroupmembership) array_ | Groups is a list of group memberships for the gateway |  |  |


#### GatewayStatus



GatewayStatus defines the observed state of Gateway.



_Appears in:_
- [Gateway](#gateway)



#### Peering



Peering is the Schema for the peerings API.





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `gateway.githedgehog.com/v1alpha1` | | |
| `kind` _string_ | `Peering` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `spec` _[PeeringSpec](#peeringspec)_ |  |  |  |
| `status` _[PeeringStatus](#peeringstatus)_ |  |  |  |


#### PeeringEntry







_Appears in:_
- [PeeringSpec](#peeringspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `expose` _[PeeringEntryExpose](#peeringentryexpose) array_ |  |  |  |


#### PeeringEntryAs







_Appears in:_
- [PeeringEntryExpose](#peeringentryexpose)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `cidr` _string_ | CIDR to include, only one of cidr, not can be set |  |  |
| `not` _string_ | CIDR to exclude, only one of cidr, not can be set |  |  |
| `ports` _string_ | Port ranges (e.g. "80, 443, 3000-3100"), used together with exactly one of cidr, not |  |  |


#### PeeringEntryExpose







_Appears in:_
- [PeeringEntry](#peeringentry)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `ips` _[PeeringEntryIP](#peeringentryip) array_ |  |  |  |
| `as` _[PeeringEntryAs](#peeringentryas) array_ |  |  |  |
| `nat` _[PeeringNAT](#peeringnat)_ |  |  |  |
| `default` _boolean_ |  |  |  |


#### PeeringEntryIP







_Appears in:_
- [PeeringEntryExpose](#peeringentryexpose)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `cidr` _string_ | CIDR to include, only one of cidr, not, vpcSubnet can be set |  |  |
| `not` _string_ | CIDR to exclude, only one of cidr, not, vpcSubnet can be set |  |  |
| `vpcSubnet` _string_ | CIDR by VPC subnet name to include, only one of cidr, not, vpcSubnet can be set |  |  |
| `ports` _string_ | Port ranges (e.g. "80, 443, 3000-3100"), used together with exactly one of cidr, not, vpcSubnet |  |  |


#### PeeringNAT







_Appears in:_
- [PeeringEntryExpose](#peeringentryexpose)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `stateful` _[PeeringStatefulNAT](#peeringstatefulnat)_ | Use connection state tracking when performing NAT |  |  |
| `stateless` _[PeeringStatelessNAT](#peeringstatelessnat)_ | Use connection state tracking when performing NAT, use stateful NAT if omitted |  |  |


#### PeeringSpec



PeeringSpec defines the desired state of Peering.



_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)
- [Peering](#peering)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `gatewayGroup` _string_ | GatewayGroup is the name of the gateway group that should process the peering |  |  |
| `peering` _object (keys:string, values:[PeeringEntry](#peeringentry))_ | Peerings is a map of peering entries for each VPC participating in the peering (keyed by VPC name) |  |  |


#### PeeringStatefulNAT







_Appears in:_
- [PeeringNAT](#peeringnat)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `idleTimeout` _[Duration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#duration-v1-meta)_ | Time since the last packet after which flows are removed from the connection state table |  |  |


#### PeeringStatelessNAT







_Appears in:_
- [PeeringNAT](#peeringnat)



#### PeeringStatus



PeeringStatus defines the observed state of Peering.



_Appears in:_
- [Peering](#peering)



#### VPCInfo



VPCInfo is the Schema for the vpcinfos API.





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `gateway.githedgehog.com/v1alpha1` | | |
| `kind` _string_ | `VPCInfo` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `spec` _[VPCInfoSpec](#vpcinfospec)_ |  |  |  |
| `status` _[VPCInfoStatus](#vpcinfostatus)_ |  |  |  |


#### VPCInfoSpec



VPCInfoSpec defines the desired state of VPCInfo.



_Appears in:_
- [VPCInfo](#vpcinfo)
- [VPCInfoData](#vpcinfodata)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `subnets` _object (keys:string, values:[VPCInfoSubnet](#vpcinfosubnet))_ | Subnets is a map of all subnets in the VPC (incl. CIDRs, VNIs, etc) keyed by the subnet name |  |  |
| `vni` _integer_ | VNI is the VNI for the VPC |  |  |


#### VPCInfoStatus



VPCInfoStatus defines the observed state of VPCInfo.



_Appears in:_
- [VPCInfo](#vpcinfo)
- [VPCInfoData](#vpcinfodata)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `internalID` _string_ |  |  |  |


#### VPCInfoSubnet







_Appears in:_
- [VPCInfoData](#vpcinfodata)
- [VPCInfoSpec](#vpcinfospec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `cidr` _string_ | CIDR is the subnet CIDR block, such as "10.0.0.0/24" |  |  |



## gwint.githedgehog.com/v1alpha1

Package v1alpha1 contains API Schema definitions for the gwint v1alpha1 API group.

### Resource Types
- [GatewayAgent](#gatewayagent)



#### BGPMessageCounters







_Appears in:_
- [BGPMessages](#bgpmessages)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `capability` _integer_ |  |  |  |
| `keepalive` _integer_ |  |  |  |
| `notification` _integer_ |  |  |  |
| `open` _integer_ |  |  |  |
| `routeRefresh` _integer_ |  |  |  |
| `update` _integer_ |  |  |  |


#### BGPMessages







_Appears in:_
- [BGPNeighborStatus](#bgpneighborstatus)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `received` _[BGPMessageCounters](#bgpmessagecounters)_ |  |  |  |
| `sent` _[BGPMessageCounters](#bgpmessagecounters)_ |  |  |  |


#### BGPNeighborPrefixes







_Appears in:_
- [BGPNeighborStatus](#bgpneighborstatus)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `received` _integer_ |  |  |  |
| `receivedPrePolicy` _integer_ |  |  |  |
| `sent` _integer_ |  |  |  |


#### BGPNeighborSessionState

_Underlying type:_ _string_

BGPNeighborSessionState represents the BGP FSM state for a neighbor.

_Validation:_
- Enum: [unset idle connect active open established]

_Appears in:_
- [BGPNeighborStatus](#bgpneighborstatus)

| Field | Description |
| --- | --- |
| `unset` |  |
| `idle` |  |
| `connect` |  |
| `active` |  |
| `open` |  |
| `established` |  |


#### BGPNeighborStatus







_Appears in:_
- [BGPVRFStatus](#bgpvrfstatus)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `enabled` _boolean_ |  |  |  |
| `localAS` _integer_ |  |  |  |
| `peerAS` _integer_ |  |  |  |
| `remoteRouterID` _string_ |  |  |  |
| `sessionState` _[BGPNeighborSessionState](#bgpneighborsessionstate)_ |  |  | Enum: [unset idle connect active open established] <br /> |
| `connectionsDropped` _integer_ |  |  |  |
| `establishedTransitions` _integer_ |  |  |  |
| `lastResetReason` _string_ |  |  |  |
| `messages` _[BGPMessages](#bgpmessages)_ |  |  |  |
| `ipv4UnicastPrefixes` _[BGPNeighborPrefixes](#bgpneighborprefixes)_ |  |  |  |
| `ipv6UnicastPrefixes` _[BGPNeighborPrefixes](#bgpneighborprefixes)_ |  |  |  |
| `l2VPNEVPNPrefixes` _[BGPNeighborPrefixes](#bgpneighborprefixes)_ |  |  |  |


#### BGPStatus



BGPStatus represents BGP status across VRFs, derived from BMP/FRR.



_Appears in:_
- [GatewayState](#gatewaystate)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `vrfs` _object (keys:string, values:[BGPVRFStatus](#bgpvrfstatus))_ | VRFs keyed by VRF name (e.g. "default", "vrfVvpc-1") |  |  |


#### BGPVRFStatus







_Appears in:_
- [BGPStatus](#bgpstatus)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `neighbors` _object (keys:string, values:[BGPNeighborStatus](#bgpneighborstatus))_ | Neighbors keyed by an ip address string |  |  |


#### DataplaneStatus



DataplaneStatus represents the status of the dataplane



_Appears in:_
- [GatewayState](#gatewaystate)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `version` _string_ |  |  |  |


#### FRRStatus



FRRStatus represents the status of the FRR daemon



_Appears in:_
- [GatewayState](#gatewaystate)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `lastAppliedGen` _integer_ | LastAppliedGen is the generation of the last successful application of a configuration to the FRR |  |  |


#### GatewayAgent



GatewayAgent is the Schema for the gatewayagents API.





| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `apiVersion` _string_ | `gwint.githedgehog.com/v1alpha1` | | |
| `kind` _string_ | `GatewayAgent` | | |
| `metadata` _[ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#objectmeta-v1-meta)_ | Refer to Kubernetes API documentation for fields of `metadata`. |  |  |
| `spec` _[GatewayAgentSpec](#gatewayagentspec)_ |  |  |  |
| `status` _[GatewayAgentStatus](#gatewayagentstatus)_ |  |  |  |


#### GatewayAgentSpec



GatewayAgentSpec defines the desired state of GatewayAgent.



_Appears in:_
- [GatewayAgent](#gatewayagent)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `agentVersion` _string_ | AgentVersion is the desired version of the gateway agent to trigger generation changes on controller upgrades |  |  |
| `gateway` _[GatewaySpec](#gatewayspec)_ |  |  |  |
| `vpcs` _object (keys:string, values:[VPCInfoData](#vpcinfodata))_ |  |  |  |
| `peerings` _object (keys:string, values:[PeeringSpec](#peeringspec))_ |  |  |  |
| `groups` _object (keys:string, values:[GatewayGroupInfo](#gatewaygroupinfo))_ |  |  |  |
| `communities` _object (keys:string, values:string)_ |  |  |  |


#### GatewayAgentStatus



GatewayAgentStatus defines the observed state of GatewayAgent.



_Appears in:_
- [GatewayAgent](#gatewayagent)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `agentVersion` _string_ | AgentVersion is the version of the gateway agent |  |  |
| `lastAppliedTime` _[Time](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#time-v1-meta)_ | Time of the last successful configuration application |  |  |
| `lastAppliedGen` _integer_ | Generation of the last successful configuration application |  |  |
| `lastHeartbeat` _[Time](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#time-v1-meta)_ | Time of the last heartbeat from the agent |  |  |
| `state` _[GatewayState](#gatewaystate)_ | State represents collected data from the dataplane API that includes FRR as well |  |  |


#### GatewayGroupInfo







_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `members` _[GatewayGroupMember](#gatewaygroupmember) array_ |  |  |  |


#### GatewayGroupMember







_Appears in:_
- [GatewayGroupInfo](#gatewaygroupinfo)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `name` _string_ |  |  |  |
| `priority` _integer_ |  |  |  |
| `vtepIP` _string_ |  |  |  |


#### GatewayState



GatewayState represents collected data from the dataplane API that includes FRR as well



_Appears in:_
- [GatewayAgentStatus](#gatewayagentstatus)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `lastCollectedTime` _[Time](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#time-v1-meta)_ | LastCollectedTime is the time of the last successful collection of data from the dataplane API |  |  |
| `dataplane` _[DataplaneStatus](#dataplanestatus)_ | Dataplane is the status of the dataplane |  |  |
| `frr` _[FRRStatus](#frrstatus)_ | FRR is the status of the FRR daemon |  |  |
| `vpcs` _object (keys:string, values:[VPCStatus](#vpcstatus))_ | VPCs is the status of the VPCs where key is the vpc (vpcinfo) name |  |  |
| `peerings` _object (keys:string, values:[PeeringStatus](#peeringstatus))_ | Peerings is the status of the VPCs peerings where key is VPC1->VPC2 and data is for one direction only |  |  |
| `bgp` _[BGPStatus](#bgpstatus)_ | BGP is BGP status |  |  |


#### PeeringStatus



PeeringStatus represents the status of a peering between a pair of VPCs in one direction



_Appears in:_
- [GatewayState](#gatewaystate)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `p` _integer_ | Packets is the number of packets sent on the peering |  |  |
| `b` _integer_ | Bytes is the number of bytes sent on the peering |  |  |
| `d` _integer_ | Drops is the number of packets dropped on the peering |  |  |
| `bps` _float_ | BytesPerSecond is the number of bytes sent per second on the peering |  |  |
| `pps` _float_ | PktsPerSecond is the number of packets sent per second on the peering |  |  |


#### VPCInfoData







_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `subnets` _object (keys:string, values:[VPCInfoSubnet](#vpcinfosubnet))_ | Subnets is a map of all subnets in the VPC (incl. CIDRs, VNIs, etc) keyed by the subnet name |  |  |
| `vni` _integer_ | VNI is the VNI for the VPC |  |  |
| `internalID` _string_ |  |  |  |


#### VPCStatus







_Appears in:_
- [GatewayState](#gatewaystate)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `p` _integer_ | Packets is the number of packets sent on the vpc |  |  |
| `b` _integer_ | Bytes is the number of bytes sent on the vpc |  |  |
| `d` _integer_ | Drops is the number of packets dropped on the vpc |  |  |


