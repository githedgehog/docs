# Known Limitations

The following is a list of current limitations of the Fabric, which we are
working hard to address:

* [Deleting a VPC and creating a new one right away can cause the agent to fail](#deleting-a-vpc-and-creating-a-new-one-right-away-can-cause-the-agent-to-fail)
* [Configuration not allowed when port is member of PortChannel](#configuration-not-allowed-when-port-is-member-of-portchannel)
* [Breakout and CMIS transceiver initialization issues on DS5000](#breakout-and-cmis-transceiver-initialization-issues-on-ds5000)
* [Traffic gets black-holed for up to 5 minutes if a host changes IP within its L3VNI VPC subnet](#traffic-gets-black-holed-for-up-to-5-minutes-if-a-host-changes-ip-within-its-l3vni-vpc-subnet)

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

### Breakout and CMIS transceiver initialization issues on DS5000

On Celestica DS5000 devices, certain transceivers using the Common Management Interface Specification (CMIS) fail to initialize properly under specific conditions.

CMIS is an open standard for managing high-speed pluggable transceivers, providing a uniform way for the network operating system to interact with and monitor them.

#### Diagnosing the issue

If you breakout a port (for example, changing from 1x800G to 2x400G or 8x100G) while no transceiver is present, and then insert a transceiver afterward, initialization may fail and the transceiver may be missing or appear as failed in SONiC.

This occurs because SONiC did not always correctly reinitialize hardware abstraction for the port after breakout and re-insertion in this scenario, especially affecting CMIS modules.

#### Resolution

- The Hedgehog Fabric agent now automatically patches `/usr/share/sonic/platform/pddf/pddf-device.json` as needed after NOS installation (the patch is indicated by `-hh1` in the description). No user action is required to apply this workaround.
- A full switch reboot is still required after agent deployment for the patch to take effect.
- The `REBOOTREQ` column for the agent object in `kubectl` or `k9s` will indicate if a reboot is needed.
- If you encounter existing transceiver failures (such as after an upgrade), a full power cycle of the switch, sometimes referred as cold boot, may still be required in addition to the reboot.

#### Additional guidance

- Prefer inserting transceivers before breaking out ports to avoid the issue altogether, if possible.
- Always follow any REBOOTREQ status after upgrades or configuration changes.
- If problems persist, perform a full power cycle as a last resort.

### Traffic gets black-holed for up to 5 minutes if a host changes IP within its L3VNI VPC subnet

When a host changes its IP address inside an L3VNI VPC subnet, leaves not directly attached to the host will
black-hole all traffic to the new IP address for up to 5 minutes, i.e., until the old neighbor is aged
out. This is due to a defect in SONiC that will be fixed in a future release.

#### Diagnosing this issue

Pings to the new IP address of the host from a remote peer will fail with `Destination Host Unreachable`.

In the remote leaf, a log like the following one can be observed, where `10.10.99.70` is the hypothetical new IP of the host:
><code>NOTICE swss#orchagent: :- handleConflictingNeighbor: Route: Add IP:10.10.99.70 vrf_id:0x844424930134944, has no matching interface</code>

#### Known workarounds

The black-hole will age out on its own after a few minutes. As a defensive measure, users can configure [static DHCP leases](../user-guide/dhcp.md#static-leases) to ensure that hosts will always receive the same IP address and prevent the issue from happening.
