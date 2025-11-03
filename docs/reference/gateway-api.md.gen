# API Reference

## Packages
- [gateway.githedgehog.com/v1alpha1](#gatewaygithedgehogcomv1alpha1)
- [gwint.githedgehog.com/v1alpha1](#gwintgithedgehogcomv1alpha1)


## gateway.githedgehog.com/v1alpha1

Package v1alpha1 contains API Schema definitions for the gateway v1alpha1 API group.

### Resource Types
- [Gateway](#gateway)
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


#### GatewayInterface



GatewayInterface defines the configuration for a gateway interface



_Appears in:_
- [GatewaySpec](#gatewayspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `pci` _string_ | PCI address of the interface (required for DPDK driver), e.g. 0000:00:01.0 |  |  |
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
| `workers` _integer_ | Workers defines the number of worker threads to use for dataplane |  |  |


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
| `cidr` _string_ |  |  |  |
| `not` _string_ |  |  |  |


#### PeeringEntryExpose







_Appears in:_
- [PeeringEntry](#peeringentry)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `ips` _[PeeringEntryIP](#peeringentryip) array_ |  |  |  |
| `as` _[PeeringEntryAs](#peeringentryas) array_ |  |  |  |
| `nat` _[PeeringNAT](#peeringnat)_ |  |  |  |


#### PeeringEntryIP







_Appears in:_
- [PeeringEntryExpose](#peeringentryexpose)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `cidr` _string_ |  |  |  |
| `not` _string_ |  |  |  |
| `vpcSubnet` _string_ |  |  |  |


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


#### GatewayAgentStatus



GatewayAgentStatus defines the observed state of GatewayAgent.



_Appears in:_
- [GatewayAgent](#gatewayagent)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `agentVersion` _string_ | AgentVersion is the version of the gateway agent |  |  |
| `lastAppliedTime` _[Time](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#time-v1-meta)_ | Time of the last successful configuration application |  |  |
| `lastAppliedGen` _integer_ | Generation of the last successful configuration application |  |  |


#### VPCInfoData







_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `subnets` _object (keys:string, values:[VPCInfoSubnet](#vpcinfosubnet))_ | Subnets is a map of all subnets in the VPC (incl. CIDRs, VNIs, etc) keyed by the subnet name |  |  |
| `vni` _integer_ | VNI is the VNI for the VPC |  |  |
| `internalID` _string_ |  |  |  |


