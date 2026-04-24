# Physical Links

The physical cables or fibers that connect the switches to each other and to
servers can be monitored with the following commands:

## Transceivers

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-02 --transceivers
NAME         PROFILE             ROLE     GROUPS    SERIAL                    STATE    GEN      APPLIED           HEARTBEAT
ds5000-02    Celestica DS5000    spine              R4028F2B125421GD200304    Ready    55/55    20 minutes ago    6 seconds ago

Transceivers:
NAME     OPER      DESCRIPTION                          CLASS    CONNECTOR       VENDOR     PART                SERIAL           CMIS
E1/1     active    OSFP112 800GBASE-DR8                 FIBER    MPO_2x12        T1NEXUS    T1O112-800G-2DR4    T100AC006346     Ready 4.0 (4)
E1/5     active    OSFP112 2x(400GBASE-CR4-DAC)-2.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-2QPC02    C2504186220      Ready 5.0 (0)
E1/61    active    OSFP112 2x(400GBASE-CR4-DAC)-2.0M    DAC      NO_SEPARABLE    FS         OSFP-800G2OPC015    C2504422334      Ready 5.0 (0)
E1/62    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504140951-1    Ready 4.0 (0)
E1/63    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504422332-2    Ready 4.0 (0)
E1/64    active    OSFP112 2x(400GBASE-CR2-DAC)-1.0M    DAC      NO_SEPARABLE    FS         OSFP-800G-PC01      C2504422333-1    Ready 4.0 (0)

Use flags for more details: -d/--details (e.g. firmware), -p/--ports, -t/--transceivers, -c/--counters, -l/--lasers
```

## Lasers

The status of the lasers is also available through the inspect commands:

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-02 --lasers
NAME         PROFILE             ROLE     GROUPS    SERIAL                    STATE    GEN      APPLIED           HEARTBEAT
ds5000-02    Celestica DS5000    spine              R4028F2B125421GD200304    Ready    55/55    21 minutes ago    11 seconds ago

Laser Status:
NAME    CHANNELS IN / OUT ( BIAS )
E1/1    0: 2.61/1.88 dBm (36.56 mA)    1: 1.07/1.72 dBm (36.56 mA)    2: 1.72/1.68 dBm (36.56 mA)    3: 2.38/1.68 dBm (36.56 mA)

Use flags for more details: -d/--details (e.g. firmware), -p/--ports, -t/--transceivers, -c/--counters, -l/--lasers
```
Often a value of `-40dBm` on the transmit or receive side indicates that the
laser is not on. If supported, check the CMIS status of the optic.


## Diagnosing a Down Fiber Link

When `kubectl fabric inspect lldp` reports an expected neighbor missing on a
port, or `kubectl fabric inspect bgp` reports an underlay neighbor that
never reaches `Established`, the most common root cause is a layer 1 fault
(optic, fiber cable, or connector) on that port. The steps below narrow
the fault to a single switch port using `kubectl fabric inspect`.

### 1. Identify the affected port

`kubectl fabric inspect lldp` prints a per-switch table of the LLDP
neighbors it observes against what the wiring expects. A port with a
blank `NEIGHBOR` / `PORT` / `DESCRIPTION` is missing its expected
neighbor entirely:

```console
core@control-1 ~ $ kubectl fabric inspect lldp
Switch: ds5000-01 (actual←→expected)
PORT       CONNECTION                      TYPE        NEIGHBOR       PORT            DESCRIPTION
E1/21/1    ds5000-01--mesh--ds5000-02      mesh
E1/22/1    ds5000-01--mesh--ds5000-02      mesh        ds5000-02      E1/22/1         Hedgehog Fabric
...
Switch: ds5000-02 (actual←→expected)
PORT       CONNECTION                        TYPE         NEIGHBOR       PORT                   DESCRIPTION
E1/21/1    ds5000-01--mesh--ds5000-02        mesh
E1/22/1    ds5000-01--mesh--ds5000-02        mesh         ds5000-01      E1/22/1                Hedgehog Fabric
...
```

Both sides of the link report an empty neighbor on `E1/21/1` while the
sibling port `E1/22/1` on the same connection reports its peer normally.
The fault is on that specific physical link between `ds5000-01` and
`ds5000-02`, not on either switch as a whole. A working sibling on the
same connection rules out a configuration problem shared by the two
ports.

`kubectl fabric inspect bgp` shows the same issue from the routing
perspective. The row for the affected port reports `STATE` as `active`
(a BGP peer that is trying to connect but never reaches `established`)
while other fabric peers on the same switch are `established`:

```console
core@control-1 ~ $ kubectl fabric inspect bgp
Switch: ds5000-01
TYPE      PORT       VRF        NEIGHBOR        REMOTE NAME          CONNECTION                    STATE          LAST ESTABLISHED
fabric    E1/21/1    default    172.30.128.1    ds5000-02/E1/21/1    ds5000-01--mesh--ds5000-02    active         a long while ago
fabric    E1/22/1    default    172.30.128.3    ds5000-02/E1/22/1    ds5000-01--mesh--ds5000-02    established    a long while ago
...
```

Both outputs name the same port (`E1/21/1`), so either starting symptom
leads to the same link.

### 2. Confirm the port is admin up but operationally down

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-01 --ports
NAME         PROFILE             ROLE           GROUPS    SERIAL                    STATE    GEN    APPLIED          HEARTBEAT
ds5000-01    Celestica DS5000    server-leaf              R4028F2B094A15GD200125    Ready    3/3    6 minutes ago    10 seconds ago

Ports:
NAME       NOS            TYPE        CONNECTION / MODE               ADM / OP     SPEED        TRANSCEIVER                          TRANSC / CMIS
E1/21      Ethernet160                                                                          OSFP112 800GBASE-DR8                 active/ready
E1/21/1    Ethernet160    mesh        ds5000-01--mesh--ds5000-02      up/down      800G
E1/22      Ethernet168                                                                          OSFP112 2x(400GBASE-CR2-DAC)-1.0M    active/ready
E1/22/1    Ethernet168    mesh        ds5000-01--mesh--ds5000-02      up/up        800G
```

!!! note
    The `NAME` column is the fabric API port name used in wiring objects and
    other `kubectl fabric inspect` commands (for example `E1/21/1`). The `NOS`
    column is the underlying NOS interface name (for example `Ethernet160`).
    Both refer to the same port.

Locate the affected port in the `ADM / OP` column. `up/down` means the
switch is trying to bring the port up but the PHY is not training, which
points at the optical path (cable, connector, or transceiver). `down/down`
means the port is intentionally disabled and the fault is at the
configuration layer instead; stop here and review the wiring object.

In the example above, `E1/21/1` is `up/down` while the sibling port
`E1/22/1` on the same connection is `up/up`, which confirms the fault is
specific to one cable rather than a switch-wide configuration issue.

### 3. Read the per-lane laser powers

```console
core@control-1 ~ $ kubectl fabric inspect switch --name ds5000-01 --lasers
NAME         PROFILE             ROLE           GROUPS    SERIAL                    STATE    GEN    APPLIED          HEARTBEAT
ds5000-01    Celestica DS5000    server-leaf              R4028F2B094A15GD200125    Ready    3/3    6 minutes ago    4 seconds ago

Laser Status:
NAME     CHANNELS IN / OUT ( BIAS )
E1/2     0: -0.47/2.83 dBm (28.25 mA)     1: 1.47/2.82 dBm (28.25 mA)      2: 0.66/2.54 dBm (28.25 mA)      3: 0.45/1.96 dBm (28.25 mA)
E1/17    0: -40.00/2.33 dBm (83.01 mA)    1: -40.00/2.24 dBm (83.10 mA)    2: -40.00/2.27 dBm (83.23 mA)    3: -40.00/2.28 dBm (83.13 mA)
E1/21    0: -40.00/0.32 dBm (28.02 mA)    1: -40.00/0.48 dBm (28.02 mA)    2: -40.00/0.45 dBm (28.02 mA)    3: -40.00/0.51 dBm (28.02 mA)
E1/66    0: -2.16/-0.93 dBm (36.61 mA)
```

Each row is one port. `IN` is receive optical power in dBm, `OUT` is
transmit optical power in dBm, and `BIAS` is transmit laser bias current
in mA. Run the same command on the far end of the affected link
(`ds5000-02` in this example) and compare.

### 4. Interpret the pattern

Using the example above, port `E1/2` is healthy (all `IN` and `OUT`
values within a few dBm of zero). Port `E1/21`, the one named in the
original LLDP/BGP error, shows all `IN` values at `-40.00 dBm` while
`OUT` values are normal: the transceiver is lasing, but no light comes
back from the far end. Port `E1/17` shows the same pattern but belongs
to an unused port and can be ignored here.

Common patterns on both ends and what they indicate:

* All `IN` values near `-40 dBm`, all `OUT` values normal: the patch
  cord is unplugged, cut, or inserted with the wrong polarity. The far
  end is not sending light back on any lane.
* Some lanes at `-40 dBm`, others near `0 dBm`, symmetric on both ends:
  one group of fibers inside the patch cord is damaged, dirty, or
  miswired; the remaining fibers are fine.
* All `OUT` values at `-40 dBm` on one end only: the transmit lasers
  on that transceiver are not emitting. Suspect a failed or partially
  inserted optic on that end.
* `IN` values swing between healthy and below `-10 dBm`: a dirty end
  face or bent fiber. Clean and reseat before replacing hardware.

The `-40 dBm` value is the "no light" measurement floor the module
reports when the receiver sees essentially no input. The low-alarm
threshold for most modern optics is around `-10 dBm`; any lane below
that threshold is enough to keep the PHY from training, even when the
other lanes are healthy.


## Ports

The inspect command will also show the connections and counters on a specific
port:

```console
core@control-1 ~ $ kubectl fabric inspect switchport -n spine-02/E1/1
Used in Connection spine-02--fabric--leaf-01:
fabric:
  links:
  - leaf:
      ip: 172.30.128.21/31
      port: leaf-01/E1/10
    spine:
      ip: 172.30.128.20/31
      port: spine-02/E1/1
  - leaf:
      ip: 172.30.128.23/31
      port: leaf-01/E1/11
    spine:
      ip: 172.30.128.22/31
      port: spine-02/E1/2

Port Counters (↓ In ↑ Out):
SPEED    UTIL  %         BITS / SEC IN    BITS / SEC OUT    PKTS / SEC IN    PKTS / SEC OUT    CLEAR    ERRORS      DISCARDS
25G      ↓   0 ↑   0     ↓ 2,432          ↑ 2,224           ↓ 3              ↑ 3               -        ↓ 0 ↑ 0     ↓ 2 ↑ 0
```
