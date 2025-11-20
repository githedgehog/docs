# Known Limitations

The following is a list of current limitations of the Fabric, which we are
working hard to address:

* [Deleting a VPC and creating a new one right away can cause the agent to fail](#deleting-a-vpc-and-creating-a-new-one-right-away-can-cause-the-agent-to-fail)
* [Configuration not allowed when port is member of PortChannel](#configuration-not-allowed-when-port-is-member-of-portchannel)
* [External peering over a connection originating from an MCLAG switch can fail](#external-peering-over-a-connection-originating-from-an-mclag-switch-can-fail)
* [Mesh limitations on TH5-based devices](#mesh-limitations-on-th5-based-devices)

### Deleting a VPC and creating a new one right away can cause the agent to fail

The issue is due to limitations in SONiC's gNMI interface. In this particular case,
the deletion and creation of a VPC back-to-back (i.e. using a script or the Kubernetes API)
can lead to the reuse of the deleted VPC's VNI before the deletion had effect.

#### Diagnosing this issue

The applied generation of the affected agent reported by kubectl will not
converge to the last desired generation. Additionally, the agent logs on the switch
(accessible at `/var/log/agent.log`) will contain an error similar to the following one:

><code>level=ERROR msg=Failed err="failed to run agent: failed to process agent config from k8s: failed to process agent config loaded from k8s: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = VNI is already used in VRF VrfVvpc-02"</code>

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

><code>level=DEBUG msg=Action idx=4 weight=13 summary="Update Interface Ethernet1 Base" command=update path="/interfaces/interface[name=Ethernet1]"</code>

><code>level=ERROR msg=Failed err="failed to run agent: failed to process agent config from file: failed to apply actions: GNMI set request failed: gnmi set request failed: rpc error: code = InvalidArgument desc = Configuration not allowed when port is member of Portchannel.</code>

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

### Mesh limitations on TH5-based devices

On TH5-based devices, such as the Celestica DS5000, mesh topologies have major
limitations:

* Failover of mesh connections using an intermediate mesh node does not
  work correctly
* Gateway peering of VPCs does not work correctly, i.e. VPCs attached to leaves
  that are not directly connected to the gateway node cannot peer properly via
  the gateway

We are investigating these issues together with our partners to determine the
root cause and possible workarounds.

#### Known workarounds

None. We recommend avoiding mesh topologies on TH5-based devices for the
time being, with the exception of 2-node topologies without gateway, where
the above issues would not apply.
