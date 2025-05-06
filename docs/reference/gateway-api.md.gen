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


#### GatewaySpec



GatewaySpec defines the desired state of Gateway.



_Appears in:_
- [Gateway](#gateway)



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
| `ingress` _[PeeringEntryIngress](#peeringentryingress) array_ |  |  |  |


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


#### PeeringEntryIP







_Appears in:_
- [PeeringEntryExpose](#peeringentryexpose)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `cidr` _string_ |  |  |  |
| `not` _string_ |  |  |  |
| `vpcSubnet` _string_ |  |  |  |


#### PeeringEntryIngress







_Appears in:_
- [PeeringEntry](#peeringentry)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `allow` _[PeeringEntryIngressAllow](#peeringentryingressallow)_ |  |  |  |


#### PeeringEntryIngressAllow







_Appears in:_
- [PeeringEntryIngress](#peeringentryingress)



#### PeeringSpec



PeeringSpec defines the desired state of Peering.



_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)
- [Peering](#peering)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `peering` _object (keys:string, values:[PeeringEntry](#peeringentry))_ | Peerings is a map of peering entries for each VPC participating in the peering (keyed by VPC name) |  |  |


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
| `vrf` _string_ | VRF (optional) is the VRF name for the VPC, if not specified, predictable VRF name is generated |  |  |


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
| `gateway` _string_ | Gateway (optional) for the subnet, if not specified, the first IP (e.g. 10.0.0.1) in the subnet is used as the gateway |  |  |
| `vni` _integer_ | VNI is the VNI for the subnet |  |  |



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
| `vpcs` _object (keys:string, values:[VPCInfoData](#vpcinfodata))_ |  |  |  |
| `peerings` _object (keys:string, values:[PeeringSpec](#peeringspec))_ |  |  |  |


#### GatewayAgentStatus



GatewayAgentStatus defines the observed state of GatewayAgent.



_Appears in:_
- [GatewayAgent](#gatewayagent)



#### VPCInfoData







_Appears in:_
- [GatewayAgentSpec](#gatewayagentspec)

| Field | Description | Default | Validation |
| --- | --- | --- | --- |
| `subnets` _object (keys:string, values:[VPCInfoSubnet](#vpcinfosubnet))_ | Subnets is a map of all subnets in the VPC (incl. CIDRs, VNIs, etc) keyed by the subnet name |  |  |
| `vni` _integer_ | VNI is the VNI for the VPC |  |  |
| `vrf` _string_ | VRF (optional) is the VRF name for the VPC, if not specified, predictable VRF name is generated |  |  |
| `internalID` _string_ |  |  |  |


