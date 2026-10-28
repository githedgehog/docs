# Gateway

This page covers diagnosing common issues with the Hedgehog Gateway, including
connectivity problems and NAT issues, and how to capture the packets going
through it.

## Health Checks

Start by verifying the gateway has picked up its current configuration:

```console
$ kubectl get gatewayagents
NAME          APPLIED             APPLIEDG   CURRENTG   VERSION   PROTOCOLIP   VTEPIP   AGE
gateway-1     10 minutes ago      10         10         v1.2.0    ...          ...      2d
```

`AppliedG` should equal `CurrentG`. If they differ, the gateway has not yet
applied the latest configuration.

If the gateway is not reporting in at all, check that its pod is running with
both containers ready. Each gateway runs as a pod named `gw--<gateway>-<suffix>`:

```console
$ kubectl get pods -n fab -l app.kubernetes.io/name=gw--gateway-1
NAME                  READY   STATUS    RESTARTS   AGE
gw--gateway-1-pwv7s   2/2     Running   0          12h
```

## Common Issues

### Traffic not flowing through gateway

1. **Check peering is configured**: Verify the GatewayPeering object exists
   and is not rejected:
   ```console
   $ kubectl get gatewaypeerings
   ```

2. **Check routes on the leaf**: Verify gateway routes are installed on the
   leaf switches:
   ```console
   $ kubectl fabric inspect vpc <vpc-name>
   ```
   Look for routes pointing to the gateway's VTEP IP.

3. **Check BGP neighbors**: Verify all BGP sessions are established (see
   [Inspecting Gateway State](#inspecting-gateway-state)).

### NAT not working as expected

1. **Check traffic is reaching the gateway**: Use the per-VPC and per-peering
   packet counters in the gateway state (see
   [Inspecting Gateway State](#inspecting-gateway-state)) to verify packets
   are being processed. Zero counters while traffic is expected indicates
   the packets are not reaching the gateway. Alternatively,
   [capture packets](#capturing-packets) traversing the gateway, filtering
   by ingress or egress VPC, and verify that they are exiting with the right
   address.

2. **Idle timeout**: If connections work briefly then stop, the flow may be
   expiring. Check the `idleTimeout` setting in the GatewayPeering spec.
   Use TCP or application-layer keepalives for long-lived connections.

### Gateway failover

1. **Check both gateways are running**: Verify both gateway pods are healthy.

2. **Check gateway group membership**:
   ```console
   $ kubectl get gateways -o yaml
   ```
   Verify both gateways are members of the expected group with correct
   priorities.

3. **Check BGP on leaves**: After a failover, the leaf switches should
   withdraw routes from the failed gateway and install routes from the
   backup. Use `kubectl fabric inspect bgp` to check. Also verify BGP
   neighbor state on the backup gateway (see
   [Inspecting Gateway State](#inspecting-gateway-state)).

## Inspecting Gateway State

The `GatewayAgent` status exposes the full operational state of the gateway,
including BGP neighbor sessions and per-VPC traffic counters.

```console
$ kubectl get gatewayagents -o yaml
```

### Configuration status

```yaml
status:
  lastAppliedGen: 10
  lastAppliedTime: "2026-04-17T16:29:04Z"
  lastHeartbeat: "2026-04-17T17:25:25Z"
  state:
    frr:
      lastAppliedGen: 10
```

- `lastAppliedGen` should match the object's `metadata.generation`. If it
  lags, the dataplane has not yet applied the current configuration.
- `state.frr.lastAppliedGen` should match `lastAppliedGen`. If it lags, FRR
  has not yet picked up the latest routing configuration.
- `lastHeartbeat` is updated periodically by the dataplane. A stale value
  indicates the dataplane is not running or not reachable.

### BGP neighbor state

```yaml
  state:
    bgp:
      vrfs:
        default:
          neighbors:
            172.30.128.12:
              sessionState: established
              localAS: 65534
              peerAS: 65100
              remoteRouterID: 172.30.8.0
              connectionsDropped: 0
              establishedTransitions: 1
              ipv4UnicastPrefixes:
                received: 6
                sent: 1
            172.30.128.26:
              sessionState: established
              ...
```

All neighbors should be in `established` state. If a neighbor is in `active`
or `idle`, the BGP session is not up; check physical connectivity and IP
configuration on both the gateway and the connected leaf switch.

A non-zero `connectionsDropped` or a high `establishedTransitions` count
indicates the session has been flapping.

### Traffic counters

Per-VPC totals:

```yaml
  state:
    vpcs:
      vpc-01:
        p: 3555    # packets
        b: 5835616 # bytes
        d: 0       # drops
```

Per-peering directional counters (present when peerings are active):

```yaml
  state:
    peerings:
      vpc-01->vpc-02:
        p: 3555
        b: 5835616
        d: 0
        bps: 254024.3
        pps: 70.2
      vpc-02->vpc-01:
        p: 2711
        b: 1000519
        d: 0
        bps: 128.9
        pps: 9.5
```

A non-zero drop counter (`d`) means packets were discarded, often due to a
misconfigured peering or an exhausted NAT pool. A zero packet counter on an
expected active peering means traffic is not reaching the gateway.

!!! note
    A drop counter of `0` only rules out drops on the gateway itself, not
    end-to-end loss. If clients see TCP retransmits while `d` stays at `0`,
    validate reachability with `kubectl fabric inspect access <A> <B>` and
    continue from the [Troubleshooting overview](overview.md).

## Capturing Packets

With the `dpdk` driver the gateway's dataplane owns its NICs, so host tools such
as `tcpdump` don't see the traffic going through it. The dataplane CLI can
instead record packets from inside the pipeline into a pcapng file, with either
driver, at two points:

- **Ingress**: each frame as it arrived, outer VXLAN header included.
- **Egress**: each frame as it leaves, re-encapsulated. Packets the gateway
  dropped are recorded here too, with the reason.

Every packet carries a comment with its metadata: direction, VNIs, input and
output port, worker thread and the verdict (`done=Delivered`, or a drop reason
such as `done=HopLimitExceeded`). Egress records also name the source and
destination VPCs; ingress records only have the VNI the packet arrived with.

### Running a capture

The CLI runs in the `dataplane` container of the gateway pod. For a gateway
named `gateway-1`:

```console
$ kubectl -n fab exec ds/gw--gateway-1 -c dataplane -- cli \
    -c 'capture start ingress=vpc-01 egress=vpc-02 seconds=30 file=/tmp/vpc-01-02.pcapng'

 capturing egress from vpc-01 to vpc-02, one packet in 1, 256 bytes of each frame, until 10000 packets or 30s
 file: /tmp/vpc-01-02.pcapng
```

Running `cli` without `-c` (and with `-it` on `kubectl exec`) opens an
interactive prompt instead. Check on a capture with `show capture`, or end it
early with `capture stop`:

```console
$ kubectl -n fab exec ds/gw--gateway-1 -c dataplane -- cli -c 'show capture'

 capture ended (duration elapsed): admitted=15 written=15 dropped=0
 file: /tmp/vpc-01-02.pcapng
```

`admitted` counts the packets that matched the filter; `dropped` counts the
ones the file writer couldn't keep up with. If `dropped` is above zero, narrow
the filter or use `sample=`.

| Argument                     | Meaning                                                    | Default                                    |
| ---------------------------- | ---------------------------------------------------------- | ------------------------------------------ |
| `ingress=VPC` or `ingress=*` | Packets arriving from that VPC                             | all traffic, if neither is given           |
| `egress=VPC` or `egress=*`   | Packets leaving towards that VPC                           | all traffic, if neither is given           |
| `ingress=A egress=B`         | Traffic from A to B, recorded at egress only               |                                            |
| `packets=N`                  | Stop after N packets                                       | 10000                                      |
| `seconds=N`                  | Stop after N seconds                                       | 60                                         |
| `sample=N`                   | Keep one matching packet in N                              | 1 (every packet)                           |
| `snaplen=N`                  | Bytes kept from each frame, `0` for whole frames           | 256 (both VXLAN headers, little payload)   |
| `file=PATH`                  | Write to this file                                         | none, `file=` or `dir=` is required        |
| `dir=PATH`                   | Write to a file with a generated name in this directory    | none, `file=` or `dir=` is required        |

Externals are named with an `ext.` prefix, for example `egress=ext.isp-a` for
external `isp-a`. An unknown name is rejected with the list of known ones.

### Getting the file

`kubectl cp` needs the pod name, so it is easier to stream the file out:

```console
$ kubectl -n fab exec ds/gw--gateway-1 -c dataplane -- cat /tmp/vpc-01-02.pcapng > vpc-01-02.pcapng
$ kubectl -n fab exec ds/gw--gateway-1 -c dataplane -- rm /tmp/vpc-01-02.pcapng
```

Open it in Wireshark: the metadata is in the packet comments, and can be
filtered on with e.g. `frame.comment contains "done=HopLimitExceeded"`.
`tcpdump` reads the file but doesn't show the comments; `capinfos` lists them.

### Things to know

- **Copy files out promptly.** `/tmp` in the dataplane container is not
  persistent: it is emptied whenever the gateway pod is recreated, for
  example when its driver is changed. Paths outside `/tmp` (and relative
  paths) are written to the container's own filesystem, with the same lifetime.
- **Existing files are not overwritten.** Pick a new name, or use `dir=`.
- **One capture at a time** per gateway.
- **Pick the right gateway.** In a gateway group, traffic for a peering goes
  through one gateway at a time, and it may not be the one you expect. If a
  capture comes back empty, try the other members of the group.
- **Keep it small.** The defaults stop at 10,000 packets or 60 seconds, keeping
  256 bytes of each. Use `snaplen=0` only for short captures where the payload
  matters.
- **Traffic to and from the gateway itself**, such as its BGP and BFD sessions,
  is not a reliable target: what the gateway sends is never captured, and what
  it receives is only captured with the `kernel` driver.
- A capture that matches nothing produces a file that some tools, including
  `tcpdump`, refuse to open. `capinfos` will correctly report 0 packets captured;
  alternatively, use the `show capture` command of the dataplane cli as in the
  example above to verify that no packets were admitted.

## Metrics

The dataplane exposes Prometheus metrics scraped by the Alloy agent on the
gateway node and forwarded to the Fabric Proxy.

Each metric is emitted with three label variants:

- `{total="<vpc>"}`: all traffic in or out of the VPC
- `{drops="<vpc>"}`: traffic dropped for the VPC
- `{from="<src>",to="<dst>"}`: directional traffic between two VPCs

Available metrics:

| Metric | Type | Description |
|--------|------|-------------|
| `vpc_packet_count` | Gauge | Packet count |
| `vpc_packet_rate` | Gauge | Packet rate |
| `vpc_byte_count` | Gauge | Byte count |
| `vpc_byte_rate` | Gauge | Byte rate |

To inspect metrics directly, run on the gateway node itself (the dataplane uses
host networking, so the endpoint is accessible on the node at port 9442):

```console
$ curl -s http://localhost:9442/metrics
```
