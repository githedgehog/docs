# Known Limitations

The following is a list of current limitations of the Fabric, which we are
working hard to address:

* [Deleting a VPC and creating a new one right away can cause the agent to fail](#deleting-a-vpc-and-creating-a-new-one-right-away-can-cause-the-agent-to-fail)
* [Configuration not allowed when port is member of PortChannel](#configuration-not-allowed-when-port-is-member-of-portchannel)
* [VPC local peering can cause the agent to fail if subinterfaces are not supported on the switch](#vpc-local-peering-can-cause-the-agent-to-fail-if-subinterfaces-are-not-supported-on-the-switch)
* [External peering over a connection originating from an MCLAG switch can fail](#external-peering-over-a-connection-originating-from-an-mclag-switch-can-fail)

### Deleting a VPC and creating a new one right away can cause the agent to fail

The issue is due to limitations in SONiC's gNMI interface. In this particular case,
the deletion and creation of a VPC back-to-back (i.e. using a script or the Kubernetes API)
can lead to the reuse of the deleted VPC's VNI before the deletion had effect.

#### Diagnosing this issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch 
(accessible at `/var/log/agent.log`) will contain an error similar to the following one:

><code>time=2025-03-23T12:26:19.649Z level=ERROR msg=Failed err="failed to run agent: failed to process agent config from k8s: failed to process agent config loaded from k8s: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = VNI is already used in VRF VrfVvpc-02"</code>

#### Known workarounds

Deleting the pending VPCs will allow the agent to reconverge. After that, the
desired VPCs can be safely created.

### Configuration not allowed when port is member of PortChannel

This is another issue related to limitations in SONiC's gNMI interface. Under some circumstances,
the agent might find itself unable to apply the desired state.

#### Diagnosing the issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch 
(accessible at `/var/log/agent.log`) will contain logs similar to the following ones:

><code>time=2025-04-08T14:35:14.555Z level=DEBUG msg=Action idx=4 weight=13 summary="Update Interface Ethernet1 Base" command=update path="/interfaces/interface[name=Ethernet1]"</code>

><code>time=2025-04-08T14:35:14.839Z level=ERROR msg=Failed err="failed to run agent: failed to process agent config from file: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = Configuration not allowed when port is member of Portchannel.</code>

#### Known workarounds

Manually setting the interface mentioned immediately before the error log to admin-up,
i.e. using the sonic-cli on the affected switch. For example, given the logs above, one would
ssh onto the switch (let's call it `s5248-01`) and do:

```
admin@s5248-01:~$ sonic-cli
s5248-01# configure
s5248-01(config)# interface Ethernet 1
s5248-01(config-if-Ethernet1)# no shutdown
```

### VPC local peering can cause the agent to fail if subinterfaces are not supported on the switch

As explained in the [Architecture page](../architecture/fabric.md#vpc-peering), to workaround
limitations in older versions of SONiC, a peering between two VPCs (or a VPC and an External) which are both
attached to the peering switch is implemented over a pair of loopback interfaces.
This workaround requires subinterface support on the switch where the peering is being
instantiated. If the affected switch does not meet this requirement, the agent will fail
to apply the desired configuration.

!!! note
    Starting from Fabric version 25.03, the loopback workaround is no longer needed.

#### Diagnosing this issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch 
(accessible at `/var/log/agent.log`) will contain an error similar to the following one:

><code>time=2025-02-04T13:37:58.796Z level=ERROR msg=Failed err="failed to run agent: failed to process agent config from k8s: failed to process agent config loaded from k8s: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = SubInterfaces are not supported"</code>

#### Known workarounds

If possible, [upgrade to 25.03 and disable the loopback workaround](../install-upgrade/upgrade.md#upgrades-to-2503).
Alternatively, configure remote VPCPeering instead of local peering in any instance where both
peering elements are locally attached and the target switch does not support subinterfaces.
You can double-check whether your switch model meets this requirement by looking at the
[Switch Profiles Catalog](../reference/profiles.md) entry for it.

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
