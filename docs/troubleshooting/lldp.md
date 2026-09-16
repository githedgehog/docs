# LLDP Neighbors

`kubectl fabric inspect lldp` reports the LLDP neighbors observed on the switch ports next to what the wiring
diagram expects on those ports, highlighting the values that don't match:

```console
core@control-1 ~ $ kubectl fabric inspect lldp
PORT       CONNECTION                    TYPE         NEIGHBOR       PORT                       MAC                  AGE / TTL
E1/1/1     leaf-1--spark-1               unbundled    spark-1.lan    enP2p1s0f0np0 (want p1)    4c:bb:47:e8:ef:fe    37/120s
E1/2/1     server-1--bundled--leaf-1     bundled      server-1       enp2s2                     6e:27:d4:e2:6b:f7    30/120s
E1/5/1     server-5--unbundled--leaf-1   unbundled    server-5 +1    enp2s1                     00:00:00:0b:bb:11    29/120s
E1/61/1    spine-1--fabric--leaf-1       fabric       spine-1        E1/61/1                    b4:db:91:9b:60:27    14/20s

Note: +N means N more neighbors on the port, use --show-all to see them
```

- A value that disagrees with the wiring is shown as `actual (want expected)`, with only the actual value
  highlighted. A port that expects a neighbor and sees none shows the expectation alone.
- When several neighbors answer on one port and one of them is the expected device, only that one is shown and
  `+N` notes the rest. `--show-all` lists all of them and marks the additional ones.
- `AGE / TTL` is the age of the neighbor entry against the TTL the neighbor advertises. Fabric links typically
  advertise 20 seconds and servers 120, so staleness is best judged against the advertised value rather than a
  fixed threshold.

Useful flags:

| Flag | Description |
| --- | --- |
| `--show-all` | Show all neighbors on a port, not just the expected one |
| `--ignore-suffix`, `--ignore-prefix` | Name parts to ignore when matching (see below) |
| `--fabric`, `--server`, `--external`, `--gateway` | Only show ports of the given connection type |

The output can also be formatted as JSON or YAML, like for the other `inspect` commands.

## Hostname matching

A server wired as `server-1` often introduces itself over LLDP as `server-1.lan`, and DPUs are usually named
similar to the hosts they sit in but with a `-dpu` suffix. Those are the same device, so some name suffixes and
prefixes are ignored when comparing the neighbor with the wiring:

- The defaults are the `-dpu`, `.lan` and `.maas` suffixes, and they can be replaced with the
  `--ignore-suffix` and `--ignore-prefix` flags.
- A name is only trimmed if trimming produces the expected name, so a device deliberately wired as
  `host-1-dpu` still matches on its full name.
- Names, port names and descriptions are compared case-insensitively.
- The ignored parts are reported: dimmed in the table, and as `ignoredPrefix`/`ignoredSuffix` in the JSON and
  YAML output.

When a server's advertised hostname is unrelated to the name of its object, it can be declared instead with the
`spec.inspect.expectedSysName` field on the `Server` object, see [Servers](../user-guide/devices.md#servers).

## Metrics

The neighbor and transceiver state above is also exported by the switch agent as Prometheus metrics on every
collection cycle, so a link that goes quiet or an optic that fails is visible without running a command. The
neighbor count, the advertised TTL, the last update time and the neighbor inventory are exported per port, as
are the transceiver presence, activity, CMIS readiness and module identity. Every interface and queue metric
also carries a `transceiver` label naming the cage the port belongs to, so link, neighbor and optic data can be
joined on a single label. See [Observability configuration](../user-guide/o11y-config.md) for how the metrics
are collected.
