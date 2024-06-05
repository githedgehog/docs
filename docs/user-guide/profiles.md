# Switch Profiles and Port Naming

## Switch Profiles

All supported switches have a `SwitchProfile` that defines the switch model, supported features, and available ports
with supported configurations such as port group and speeds as well as port breakouts. `SwitchProfiles` available
in-cluster or generated documentation can be found in the [Reference section](../reference/profiles.md).

Each switch used in the wiring diagram should have a `SwitchProfile` references in the `spec.profile` of the `Switch`
object.

Switch profile defines what features and ports are available on the switch. Based on the ports data in the profile, it's
possible to set port speeds (for non-breakout and non-group ports), port group speeds and port breakout modes in the
`Switch` object in the Fabric API.

## Port Naming

Each switch port is named using one of the the following formats:

- `M<management-port-number>`
    - `<management-port-number>` is the management port number starting from `1` (usually only one named `1` for most
  switches)

- `E<asic-or-chassis-number>/<port-number>[/<breakout>][.<subinterface.]`
    - `<asic-or-chassis-number>` is the ASIC or chassis number (usually only one named `1` for the most switches)
    - `<port-number>` is the port number on the ASIC or chassis, starting from `1`
    - optional `/<breakout>` is the breakout number for the port, starting from `1`, only for breakout ports and always
    consecutive numbers independent of the lanes allocation and other implementation details
    - optional `.<subinterface>` is the subinterface number for the port

Examples of port names:

- `M1` - management port
- `E1/1` - port `1` on the ASIC or chassis `1`, usually a first port on the switch
- `E1/55/1` - first breakout port of the switch port `55` on the ASIC or chassis `1`

## Available Ports

Each switch profile defines a set of ports available on the switch. Ports could be divided into the following types.

### Directly configurable ports

Non-breakout and non-group ports. Would have a reference to the port profile with default and available speeds. Could
be configured by setting the speed in the `Switch` object in the Fabric API:

```yaml
.spec:
  portSpeeds:
    E1/1: 25G
```

### Port groups

Ports that belong to a port group, non-breakout and not directly configurable. Would have a reference to the port group
which will have a reference to the port profile with default and available speeds. Port couldn't be configured directly,
speed configuration is applied to the whole group in the `Switch` object in the Fabric API:

```yaml
.spec:
  portGroupSpeeds:
    "1": 10G
```

It'll set the speed of all ports in the group `1` to `10G`, e.g. if the group `1` contains ports `E1/1`, `E1/2`, `E1/3`
and `E1/4`, all of them will be set to `10G` speed.

### Breakout ports

Ports that are breakouts and non-group ports. Would have a reference to the port profile with default and available
breakout modes. Could be configured by setting the breakout mode in the `Switch` object in the Fabric API:

```yaml
.spec:
  portBreakouts:
    E1/55: 4x25G
```

Configuring a port breakout mode will make "breakout" ports available for use in the wiring diagram. The breakout ports
are named as `E<asic-or-chassis-number>/<port-number>/<breakout>`, e.g. `E1/55/1`, `E1/55/2`, `E1/55/3`, `E1/55/4` for
the example above. Omitting the breakout number is allowed for the first breakout port, e.g. `E1/55` is the same as
`E1/55/1`. The breakout ports are always consecutive numbers independent of the lanes allocation and other
implementation details.

### Management ports

Not configurable, no port profile, only used for connecting the switch to the control node.
