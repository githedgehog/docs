# Gateway

This page covers diagnosing common issues with the Hedgehog Gateway, including
connectivity problems and NAT issues.

## Health Checks

Start by verifying the gateway has picked up its current configuration:

```console
$ kubectl get gatewayagents
NAME          APPLIED             APPLIEDG   CURRENTG   VERSION   PROTOCOLIP   VTEPIP   AGE
gateway-1     10 minutes ago      10         10         v1.2.0    ...          ...      2d
```

`AppliedG` should equal `CurrentG`. If they differ, the gateway has not yet
applied the latest configuration.

If the gateway is not reporting in at all, check that both pods are running:

```console
$ kubectl get pods -n fab -l app.kubernetes.io/component=gateway
NAME                               READY   STATUS    RESTARTS   AGE
gw--gateway-1--dataplane-7v9ss     1/1     Running   0          12h
gw--gateway-1--frr-c9kwc           2/2     Running   0          12h
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
   the packets are not reaching the gateway.

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
