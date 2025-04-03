# Known Issues

The following is a list of current limitations of the Fabric, which we are
working hard to address:

* [Deleting a VPC and creating a new one right away can cause the agent to fail](#deleting-a-vpc-and-creating-a-new-one-right-away-can-cause-the-agent-to-fail)
* [VPC local peering can cause the agent to fail if subinterfaces are not supported on the switch](#vpc-local-peering-can-cause-the-agent-to-fail-if-subinterfaces-are-not-supported-on-the-switch)
* [External peering over a connection originating from an MCLAG switch can fail](#external-peering-over-a-connection-originating-from-an-mclag-switch-can-fail)
* [MCLAG leaf with no surviving spine connection will blackhole traffic](#mclag-leaf-with-no-surviving-spine-connection-will-blackhole-traffic)

### Deleting a VPC and creating a new one right away can cause the agent to fail

The issue is due to limitations in SONiC's gNMI interface. In this particular case,
the deletion and creation of a VPC back-to-back (i.e. using a script or the golang API)
can lead to the reuse of the deleted VPC's VNI before the deletion had effect.

#### Diagnosing this issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch 
(accessible at `/var/log/agent.log`) will contain an error similar to the following one:

```
time=2025-03-23T12:26:19.649Z level=ERROR msg=Failed err="failed to run agent: failed to process agent config from k8s: failed to process agent config loaded from k8s: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = VNI is already used in VRF VrfVvpc-02"
```

#### Known workarounds

Deleting the pending VPCs will allow the agent to reconverge. After that, the
desired VPCs can be safely created.

### VPC local peering can cause the agent to fail if subinterfaces are not supported on the switch

As explained in the [Architecture page](../architecture/fabric.md#vpc-peering), to workaround
limitations in SONiC, local VPCPeering is implemented over a pair of loopback interfaces.
This workaround requires subinterface support on the switch where the VPCPeering is being
instantiated. If the affected switch does not meet this requirement, the agent will fail
to apply the desired configuration.

#### Diagnosing this issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch 
(accessible at `/var/log/agent.log`) will contain an error similar to the following one:

```
time=2025-02-04T13:37:58.675Z level=DEBUG msg=Action idx=90 weight=33 summary="Create Subinterface Base 101" command=update path="/interfaces/interface[name=Ethernet16]/subinterfaces/subinterface[index=101]"
time=2025-02-04T13:37:58.796Z level=ERROR msg=Failed err="failed to run agent: failed to process agent config from k8s: failed to process agent config loaded from k8s: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = SubInterfaces are not supported"
```

#### Known workarounds

Configure remote VPCPeering wherever local peering would target a switch not supporting
subinterfaces. You can double-check whether your switch model supports them by looking at
the [Switch Profiles Catalog](../reference/profiles.md) entry for it.

### External peering over a connection originating from an MCLAG switch can fail

When importing routes via [External Peering](../user-guide/external.md) over a connection
originating from an MCLAG leaf switch, traffic from the peered VPC towards that
prefix can be blackholed. This is due to a routing mismatch between the two MCLAG leaves,
where only one switch learns the imported route. Packets hitting the "wrong" leaf will
be dropped with a Destination Unreachable error.

#### Diagnosing this issue

No connectivity from the workload server(s) in the VPC towards the prefix routed via the external.

#### Known workarounds

Connect your externals to non-MCLAG switches instead.

### MCLAG leaf with no surviving spine connection will blackhole traffic

When a leaf switch in an MCLAG pair loses its last uplink to the spine, the BGP
session to the spine goes down, causing the leaf to stop advertising and receiving
EVPN routes. This leads to blackholing of traffic for endpoints connected to the
isolated leaf, as the rest of the fabric no longer has reachability information for
those endpoints, even though the MCLAG peering session is up.

#### Diagnosing this issue

Traffic destined for endpoints connected to the leaf is blackholed. All BGP sessions
from the affected leaf towards the spines are down.

#### Known workarounds

None.
