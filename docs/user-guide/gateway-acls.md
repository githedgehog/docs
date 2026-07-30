# Gateway Peering ACLs

A [Gateway Peering](gateway-peering.md) can carry an **Access Control List
(ACL)**: an ordered list of rules that decides, for each new flow or packet,
whether the gateway admits it or drops it. ACLs are configured via the
optional, peering-scoped `spec.acl` field.

ACLs are **opt-in**: a peering with no `spec.acl` behaves exactly as described
in [Gateway Peering](gateway-peering.md).

The full list of fields is in the
[Fabric & Gateway APIs reference](../reference/fabric-api.md#peeringacl).

## Traffic filtering in Gateway Peerings

Several mechanisms restrict what traffic can flow between the two VPCs of a
Gateway Peering. Before any ACL rule is evaluated, the first mechanism is the
definition of the peering itself, via the prefixes in the `expose` blocks: when
the gateway receives a packet, it attempts to determine its destination VPC by
finding the right peering based on the source VPC, source IP and port,
destination IP and port (ports are used in the case of port-forwarding). If a
packet does not match prefixes from exposed blocks in any peering attached to
its source VPC, it is dropped.

Some stateful NAT modes, such as masquerade and port-forwarding, add a second
restriction: a flow may only be initiated in one direction. When masquerade is
set-up, a flow can only be initiated from the VPC with the masqueraded
prefixes; a packet sent towards a masqueraded host will be dropped if the
gateway has no associated stateful flow entry in its table, even if the address
is otherwise valid with regards to the peering definition. Conversely, flows
can only be initiated towards, and never from, an endpoint using
port-forwarding.

**ACL rules** come as a third mechanism, and **add explicit allow/deny**
decisions based on 5-tuples. Traffic restrictions from ACL rules come in
addition to the restrictions implied by the Gateway Peering definition. In
other words, an ACL rule will **never allow any packet that is not permitted by
the prefixes exposed** in the peering configuration.

## ACL configuration

To configure an ACL, use field **`spec.acl`** alongside `spec.peering`. The ACL
applies to the whole peering. The YAML definition for the `expose` blocks
remains unchanged. Here is an example:

```{.yaml .annotate linenums="1" title="gw-acl-peer.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: GatewayPeering
metadata:
  name: vpc-app--vpc-db
  namespace: default
spec:
  peering:
    vpc-app:
      expose:
        - ips:
          - cidr: 10.0.1.0/24
          as:
          - cidr: 192.168.1.0/24
          nat:
            masquerade:
              idleTimeout: 5m0s
    vpc-db:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
  acl:
    # Default action when no rule matches; "deny-unless-exposed" if omitted
    default: deny
    rules:
      - name: app-to-db # Optional, used in logs and diagnostics
        # Either "from" or "to" may be omitted (not both)
        from: vpc-app   # Side initiating the flow
        to: vpc-db      # Side receiving the flow
        action: allow   # "allow" or "deny" - required
        match:
          src:          # From-side native (pre-NAT) prefix
            - cidr: 10.0.1.0/24
          dst:          # To-side advertised prefix, as exposed to the peer
            - cidr: 10.0.2.0/24
              ports: ["5432"]
          proto: tcp    # Omit to match any protocol
        scope: flow     # "flow" (default; match reply traffic) or "packet"
        log: false      # true or false (default)
```

This peering lets hosts in prefix `10.0.1.0/24` from `vpc-app` open TCP
connections on port `5432` to hosts with prefix `10.0.2.0/24` from `vpc-db`,
allows return traffic to go through as well, and nothing else (`default: deny`)
in either direction.

### Rule evaluation order

The gateway evaluates rules in `spec.acl.rules` top-down: **the first rule
whose `from`/`to` and `match` pattern match the flow decides the verdict**, and
evaluation stops immediately. If no rule matches, `spec.acl.default` applies.
Conflicts between rules are resolved purely by order, so a broad rule placed
early will shadow the more specific rules that follow it.

### Rule direction: `from` and `to`

Every rule specifies a **direction**. Fields **`from`** and **`to`** must each
name one of the peering's two sides, using the same names as the keys under
`spec.peering` (externals included, prefixed with `ext.`). A rule applies to
packets emitted by `from` towards `to`.

Because a peering always has exactly two sides, one of `from` or `to` may be
omitted, and the other side is implied. Omitting both is not allowed.

Depending on the `scope` specified for the rule, rules may also apply to
packets of an established flow's reverse direction. Refer to [the section on
rule scope](#rule-scope) for details.

### Matching patterns

The `match` block defines what packets (or flows) an ACL rule applies to.

#### NAT considerations

The gateway evaluates ACL rules for a packet **before any NAT is applied**.
This means that the patterns in the `match` block are compared with the **real
source address** and the **destination address the initiator used** (typically,
its exposed service address).

For example, let's consider `vpc-01` exposing `10.0.1.0/24` (without NAT), and
`vpc-02` exposing a private address `10.0.2.10` behind port-forwarding, as
public address `100.64.2.10/32`:

- To write a rule to allow endpoint `10.0.1.1` on `vpc-01` to reach a server
  exposed as a service behind `100.64.2.10` on `vpc-02`, there is no need to
  account for the translated address. As ACL rules are evaluated before NAT (in
  this case, port-forwarding) takes place, the destination address
  `100.64.2.10` is used to write the rule, regardless of what private address
  in `vpc-02` the gateway translates it to.

- To write a rule to forbid the server on `vpc-02` to talk to some endpoint
  (say, `10.0.1.4`) on `vpc-01`, the same applies, in the opposite direction:
  the ACL rule evaluation comes before NAT, which means we use the private IP
  address for the server, `10.0.2.10`, and the plain destination address of the
  endpoint at `10.0.1.4`, to write the match pattern (although in the current
  case, the server is already forbidden to initiate connections by the peering
  definition, because it is exposed using port-forwarding).

#### Match block

The `match` block is a 5-tuple, expressed from the initiator's point of view:

- **`src`** contains the `from` side's native address prefixes and ports
- **`dst`** contains the `to` side's advertised address prefixes and ports
  (from its `expose`'s `as`, or `ips` where no NAT applies)
- **`proto`** can be `tcp`, `udp`, or a quoted [protocol number] (for example:
  `"132"` for SCTP)

`src` and `dst` are lists of
[match endpoints](../reference/fabric-api.md#peeringaclmatchendpoint). Each
entry carries an IP prefix and an optional list of ports, where a port entry is
either a single port such as `"80"` (do not omit the quotes) or an inclusive
range such as `"8000-8100"`. The prefix takes the same shape as an `expose`
entry: either a literal `cidr`, or a `vpcSubnet` reference naming a VPC subnet.
At most one of `cidr` and `vpcSubnet` can be set on a given entry.

Here are some match block examples:

- Match all UDP traffic towards hosts in prefix `10.0.2.0/24`:

  ```yaml
  match:
    dst:
      - cidr: 10.0.2.0/24
    proto: udp
  ```

- Match all TCP traffic with destination port 25, for all exposed IP addresses
  on the relevant side of the peering:

  ```yaml
  match:
    dst:
      - ports: ["25"]
    proto: tcp
  ```

- Match all TCP traffic from prefixes `10.0.1.0/24` and `10.0.2.0/24`, to
  prefix `10.0.5.0/24` with destination port 5432:

  ```yaml
  match:
    src:
      - cidr: 10.0.1.0/24
      - cidr: 10.0.2.0/24
    dst:
      - cidr: 10.0.5.0/24
        ports: ["5432"]
    proto: tcp
  ```

- Match UDP traffic from IP address `10.0.2.12` with source port between 8000
  and 8100 inclusive, or equal to 9000, to any valid destination defined by the
  peering:

  ```yaml
  match:
    src:
      - cidr: 10.0.2.12/32
        ports: ["8000-8100", "9000"]
    proto: udp
  ```

- Match all traffic between `10.0.1.1` and `10.0.2.1`, regardless of protocol
  and ports:

  ```yaml
  match:
    src:
      - cidr: 10.0.1.1/32
    dst:
      - cidr: 10.0.2.1/32
  ```

- Match all TCP traffic in the rule's direction. Non-TCP traffic does not match
  the rule.

  ```yaml
  match:
    proto: tcp
  ```

- Match SCTP traffic from `10.0.1.1` to `10.0.2.1`:

  ```yaml
  match:
    src:
      - cidr: 10.0.1.1/32
    dst:
      - cidr: 10.0.2.1/32
    proto: "132"
  ```

Note that source and destination ports can only be used when the `proto` field
is set to `tcp` or `udp`.

!!! tip
    Field `proto` supports values `tcp`, `udp`, or a quoted protocol number. An
    `icmp` keyword should be added in the future, with related matching options
    such as error types; until then, you can use protocol number `"1"` to match
    ICMP packets.

[protocol number]: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml

#### Optional `match` fields

Everything in `match` is optional, and omitting a field widens the rule:

| Field | If omitted, then... |
| --- | --- |
| `src`, `dst` | the rule matches any source or destination address and port within the peering configuration, respectively |
| `src.{cidr,vpcSubnet}`, `dst.{cidr,vpcSubnet}` | the rule matches any source or destination IP address within the peering configuration (respectively), but can still be restricted to specified port ranges |
| `src.ports`, `dst.ports` | the rule matches all source or destination ports within the peering configuration, respectively |
| `proto` | the rule matches any protocol |

If the `match` block is omitted altogether, the rule matches every flow in the
specified direction: this is how to write a generic allow or deny for one
direction.

### Rule scope

The **`scope` field** in each rule selects whether the rule is stateful:

- **`flow`** (the default) makes the rule **bidirectional for established
  connections**. Once a flow is admitted, its return traffic is matched by the
  flow table entry and allowed even if it does not match any other explicit
  allow rule. The connection can still only be _initiated_ in the rule's
  direction.
- **`packet`** makes the rule stateless. **Return traffic is not implicitly
  allowed** and must be permitted by a separate rule.

Note that under `default: deny`, a rule with `scope: packet` and no matching
reverse rule admits the forward direction **while dropping every reply**. Add
an explicit rule for the return direction whenever you use `scope: packet` and
need bidirectional traffic.

Also, note that reply traffic for allow rules with `scope: flow` may still be
dropped if it matches an explicit deny rule in the list: packets are evaluated
as potential "return traffic" only after going through a first direct lookup
against the ACL rules table.

The scope does not matter in the case of `deny` rules, given that no flow
matching this rule can be initiated in the first place.

!!! warning
    Due to internal limitations in the gateway, `scope: flow` is currently
    **restricted** to peerings for which **all flows use masquerade or
    port-forwarding**. Flows relying on static NAT, or no NAT at all, do not
    currently generate stateful entries in the gateway's table. This limitation
    will be lifted in a future release.

### Default action

**When no rule matches, the default verdict from `spec.acl.default` is
applied**. The field can take one of two values:

- **`deny-unless-exposed`** (the default) **denies the packet unless it
  corresponds to a defined peering**. This means that the packet is rejected
  unless it matches the following conditions:

    1. Its source VPC, source IP address, and destination address match exposed
       prefixes (and source or destination ports match exposed port ranges, in
       the case of port-forwarding) for a peering attached to the source VPC.
    2. If the packet attempts to establish a new flow, the NAT modes in use —
       as defined in the relevant `expose` blocks for the peering — do not
       prevent it.
    3. No deny rule in the ACL matches the packet.

  See also the section about
  [traffic filtering in Gateway Peerings](#traffic-filtering-in-gateway-peerings).
  If a packet matches all these conditions, then `deny-unless-exposed` allows
  it to go through.

- **`deny`** means **that packets not explicitly allowed by a rule** (or
  corresponding to return traffic for an established flow allowed by a rule
  with `scope: flow`) **are dropped**. So even a packet that matches the
  peering is dropped if no allow rule matches it.

### Logging

Set the `log` field of a rule to `true` to log all packets matching that rule
(as well as corresponding reply traffic, for rules with `scope: flow`). The
rule's name, if specified, appears in the log message.

## Examples

This section contains some example use cases and configuration for the peering
ACLs.

### Restricting an exposed service

VPC `vpc-02` only publishes a backend as `100.64.2.10:443`.

```{.yaml .annotate linenums="1" title="gw-acl-port-fw-service.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: GatewayPeering
metadata:
  name: vpc-01--vpc-02
  namespace: default
spec:
  peering:
    vpc-01:
      expose:
        - ips:
          - cidr: 10.0.1.0/24    # No NAT
    vpc-02:
      expose:
        - ips:
          - cidr: 10.0.2.10/32
          as:
          - cidr: 100.64.2.10/32 # Expose 10.0.2.10:8443 as 100.64.2.10:443
          nat:
            portForward:
              ports:
                - proto: tcp
                  port: "8443"
                  as: "443"
  acl:
    default: deny       # Deny packets even if they match the peering
    rules:
      - name: vpc-01-workloads-to-web   # Name of the rule, for logging
        from: vpc-01    # Rule applies to packets from vpc-01 to vpc-02
        to: vpc-02      # (Optional, implied by "from: vpc-01")
        action: allow   # Allow matching packets
        match:
          dst:
            - cidr: 100.64.2.10/32  # The IP vpc-01 sends to: vpc-02's "as"
              ports: ["443"]        # Match traffic to port 443 only...
          proto: tcp                # ... and for TCP only
        scope: flow                 # Allow return traffic for flows
```

A flow from `10.0.1.5` to `100.64.2.10:443` is evaluated before NAT, so the
rule matches `vpc-02`'s backend address before port-forwarding takes place.
Based on the `scope`, reply traffic is automatically allowed.

### Egress allow-list towards an external

A private subnet reaches the Internet through masquerade, with a strict list of
allowed destination ports, and one carve-out rule placed ahead of it.

```{.yaml .annotate linenums="1" title="gw-acl-egress.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: GatewayPeering
metadata:
  name: vpc-internal--ext
  namespace: default
spec:
  peering:
    vpc-internal:
      expose:
        - ips:
          - cidr: 10.0.0.0/16
          as:
          - cidr: 198.51.100.7/32
          nat:
            masquerade:
              idleTimeout: 5m0s
    ext.internet:
      expose:
        - default: true
  acl:
    default: deny       # Deny packets even if they match the peering
    rules:
      - name: block-blackholed-ranges
        from: vpc-internal  # "to" is omitted: the external side is implied
        action: deny    # Deny traffic to the following prefixes/address
        match:
          dst:
            - cidr: 192.0.2.0/24
            - cidr: 198.51.100.66/32
      - name: allow-web
        from: vpc-internal
        action: allow   # Allow TCP traffic to ports 80 and 443,
        match:          # only for traffic not denied by the first rule
          proto: tcp
          dst:
            - ports: ["80", "443"]
        scope: flow     # Also allow return traffic
      - name: allow-dns
        from: vpc-internal
        action: allow   # Allow UDP traffic to port 53,
        match:          # only for traffic not denied by the first rule
          proto: udp
          dst:
            - ports: ["53"]
        scope: flow     # Also allow return traffic
```

Match field `src` is omitted throughout, so it matches any address
`vpc-internal` exposes through the peering. The `deny` rule comes first because
the first match decides the verdict: moving `allow-web` above
`block-blackholed-ranges` would allow HTTP/HTTPS towards the blackholed ranges.

### Bidirectional traffic with static NAT

In the following setup, `vpc-01` exposes a prefix using static NAT, and uses an
ACL to restrict communications to a few hosts within the prefix. Rules apply
per packet and not per flow (`scope: packet`), meaning that the return traffic
has to be explicitly allowed.

```{.yaml .annotate linenums="1" title="gw-acl-bidir.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: GatewayPeering
metadata:
  name: vpc-01--vpc-02
  namespace: default
spec:
  peering:
    vpc-01:
      expose:
        - ips:
          - cidr: 10.0.1.10/32
          as:
          - cidr: 192.168.0.10/32
          nat:
            static: {}
    vpc-02:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
  acl:
    default: deny       # Deny packets even if they match the peering
    rules:
      - from: vpc-01
        action: allow   # Allow traffic from 10.0.1.10 (private address,
                        # before source NAT) to 10.0.2.28
        match:
          src:
            - cidr: 10.0.1.10/32
          dst:
            - cidr: 10.0.2.28/32
        scope: packet   # Return traffic is not automatically allowed
      - from: vpc-02
        action: allow   # Allow traffic from 10.0.2.{12,28} to 192.168.0.10
                        # (exposed address, before reverse destination NAT)
        match:
          src:
            - cidr: 10.0.2.12/32
            - cidr: 10.0.2.28/32
          dst:
            - cidr: 192.168.0.10/32
        scope: packet   # Return traffic is not automatically allowed
```

Endpoint `10.0.2.28` from `vpc-02` can communicate with `10.0.1.10` from
`vpc-01` both ways, thanks to the first rule allowing traffic from `10.0.1.10`;
however, endpoint `10.0.2.12` from `vpc-02` can emit towards `10.0.1.10`, but
will not receive any return traffic.

### Blocking sub-ranges

Here is a peering where `vpc-01` only exposes portions of subnet `10.0.1.0/24`
to `vpc-02`. This example illustrates how ACL rules can provide finer-grained
control than the `expose` block: it offers control over direction, protocol,
and port ranges.

```{.yaml .annotate linenums="1" title="gw-acl-subranges.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: GatewayPeering
metadata:
  name: vpc-01--vpc-02
  namespace: default
spec:
  peering:
    vpc-01:
      expose:
        - ips:
          - cidr: 10.0.1.0/24
          - not: 10.0.1.64/26
    vpc-02:
      expose:
        - ips:
          - cidr: 10.0.2.0/24
  acl:
    default: deny-unless-exposed # Deny unless packets match the peering
    rules:
      - from: vpc-01
        action: deny    # Restrict traffic coming from vpc-01
        match:
          src:
            - cidr: 10.0.1.128/26 # Block source IP range
      - from: vpc-01
        action: deny    # Restrict further traffic from vpc-01
        match:
          src:
            - cidr: 10.0.1.192/27 # Block TCP from 10.0.1.192/27:2000-3000
              ports: ["2000-3000"]
          proto: tcp
      - from: vpc-02
        action: deny    # Also restrict traffic coming from vpc-02
        match:
          dst:
            - cidr: 10.0.1.234/32   # Block UDP traffic to 10.0.1.234:53
              ports: ["53"]
          proto: udp
```

With this configuration, when `vpc-01` sends packets towards `vpc-02`:

- All packets that do not come from `10.0.1.0/24`, or are not addressed to
  `10.0.2.0/24`, are dropped, because they do not match the peering definition.
- From `10.0.1.0/26`: Packets match the peering and do not match any deny rule,
  so `deny-unless-exposed` lets them pass.
- From `10.0.1.64/26`: Per the peering definition, this sub-prefix is not part
  of the exposed block (`not:`), so packets are dropped.
- From `10.0.1.128/26`: Because of the first ACL rule, packets are dropped.
- From `10.0.1.192/27`:
    - TCP traffic is dropped for source ports between 2000 and 3000
      (inclusive), because of the second rule.
    - TCP traffic from other ports is allowed by `deny-unless-exposed`.
    - Non-TCP traffic is allowed by `deny-unless-exposed`.
- From `10.0.1.224/27`: Packets match the peering and do not match any deny
  rule, so `deny-unless-exposed` lets them pass.

And when `vpc-02` sends packets towards `vpc-01`:

- All packets that do not come from `10.0.2.0/24`, or are not addressed to
  `10.0.1.0/24`, are dropped, because they do not match the peering definition.
- To `10.0.1.0/26`: Packets match the peering and do not match any deny rule,
  so `deny-unless-exposed` lets them pass.
- To `10.0.1.64/26`: Per the peering definition, this sub-prefix is not part of
  the exposed block (`not:`), so packets are dropped.
- To `10.0.1.234`:
    - UDP traffic to port 53 is dropped, because of the third rule.
    - UDP traffic to other ports is allowed by `deny-unless-exposed`.
    - Non-UDP traffic is allowed by `deny-unless-exposed`.
- To other addresses in `10.0.1.0/24`: Packets match the peering and do not
  match any deny rule — the first two rules in the list do not apply to traffic
  in this direction — so `deny-unless-exposed` lets them pass.
