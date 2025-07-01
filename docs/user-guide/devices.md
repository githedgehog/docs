# Switches and Servers

All devices in a Hedgehog Fabric are divided into two groups: switches and servers, represented by the corresponding
`Switch` and `Server` objects in the API. These objects are needed to define all of the participants of the Fabric and their
roles in the Wiring Diagram, together with `Connection` objects (see [Connections](./connections.md)).

## Switches

Switches are the main building blocks of the Fabric. They are represented by `Switch` objects in the API. These objects
consist of basic metadata like name, description, role, serial, management port mac, as well as port group speeds, port breakouts, ASN,
IP addresses, and more. Additionally, a `Switch` contains a reference to a `SwitchProfile` object that defines the switch
model and capabilities. More details can be found in the [Switch Profiles and Port Naming](./profiles.md) section.

In order for the fabric to manage a switch the profile needs to include either the `serial` or `mac` need to be defined in the YAML doc.

```{.yaml .annotate linenums="1" title="Switch.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: s5248-01
  namespace: default
spec:
  boot: # at least one of the serial or mac needs to be defined
    serial: XYZPDQ1234
    mac: 00:11:22:33:44:55 # Usually the first management port MAC address
  profile: dell-s5248f-on # Mandatory reference to the SwitchProfile object defining the switch model and capabilities
  asn: 65101 # ASN of the switch. User provided if exapanding the fabric.
  description: leaf-1
  ip: 172.30.0.8/21 # Switch IP that will be accessible from the Control Node, if expanding the fabric, IP is user-supplied
  portBreakouts: # Configures port breakouts for the switch, see the SwitchProfile for available options
    E1/55: 4x25G
  portGroupSpeeds: # Configures port group speeds for the switch, see the SwitchProfile for available options
    "1": 10G
    "2": 10G
  portSpeeds: # Configures port speeds for the switch, see the SwitchProfile for available options
    E1/1: 25G
  protocolIP: 172.30.11.100/32 # Used as BGP router ID
  role: server-leaf # Role of the switch, one of: spine, server-leaf, border-leaf, or mixed-leaf
  vlanNamespaces: # Defines which VLANs could be used to attach servers
  - default
  vtepIP: 172.30.12.100/32
  groups: # Defines which groups the switch belongs to, by referring to SwitchGroup objects
  - some-group
  redundancy: # Optional field to define that switch belongs to the redundancy group
    group: eslag-1 # Name of the redundancy group
    type: eslag # Type of the redundancy group, one of mclag or eslag
  enableAllPorts: true # Optional field to enable all ports on the switch by default
  portAutoNegs: # Used for rj45 copper ports, and 800G ports for link conditioning
    E1/18: true
    E1/19: false
  roce: false # Lossless queues, RoCEv2 and related QoS configurations
  ecmp:
    roceQPN: false # ECMP RoCE QPN hashing
```

### RDMA over Converged Ethernet (RoCE) version 2
RDMA over converged ethernet (RoCE) allows for RDMA communication over conventional
ethernet devices. RoCE isn't available on every switch, check the [switch
catalog](../reference/profiles.md) for `RoCE: true`. Enabling RoCE on a switch
requires the switch to reboot in order to configure the hardware and associated
queues. Once a switch is in RoCE mode the port breakouts cannot be changed.
!!! warning
    Users are advised to set the port breakouts as desired, and confirm
    the link is up before enabling RoCE.

#### RoCE Lossless mode

When enabling RoCE on a switch, the buffers inside the switch are configured to
be lossless, and ingress traffic is classified based on the DSCP value inside
the IP packet header.

|Purpose | DSCP Values | Traffic Class|
| ---    | ---         | --- |
|RDMA    |  24  |  3  |
|RDMA    |  26  |  3  |
|Congestion Notification |  48  |  6  |
| unknown |  all others  |  0  |

The counters associated with the traffic classes are viewable using the
`kubectl fabric inspect` command. Users are advised to test traffic and track
the counters to ensure that proper end host configuration is achieved. Often
RDMA enabled software bypasses the host software stack. This bypass means that
configuration with utilities like: `nft`,`iptables`, and `iproute2` will not
affect RDMA traffic leaving the host.


When RoCE traffic is using VXLAN, the inner packet DSCP information is copied
to the outer packet at the time of encapsulation. Likewise the outer DSCP
information is copied to the inner packet when the packet is deencapsulated.
This process preserves the traffic classification even through a VXLAN tunnel.

#### RoCE QPN Hashing Mode

RoCE traffic adds another input for hashing of traffic to ensure load
sharing. The `ecmp.roceQPN` option will enable the use of the queue pair
number as part of the hashing calculation. It is recommended that RoCE
users also enable this `ecmp` setting.

## Switch Groups

The `SwitchGroup` is just a marker at that point and doesn't have any configuration options.

```{.yaml .annotate linenums="1" title="SwitchGroup.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: SwitchGroup
metadata:
  name: border
  namespace: default
spec: {}
```

## Redundancy Groups

Redundancy groups are used to define the redundancy between switches. It's a regular `SwitchGroup` used by multiple
switches and currently it could be MCLAG or ESLAG (EVPN MH / ESI). A switch can only belong to a single redundancy
group.

MCLAG is only supported for pairs of switches and ESLAG is supported for up to 4 switches. Multiple types of redundancy
groups can be used in the fabric simultaneously.

Connections with types `mclag` and `eslag` are used to define the servers connections to switches. They are only
supported if the switch belongs to a redundancy group with the corresponding type.

In order to define a MCLAG or ESLAG redundancy group, you need to create a `SwitchGroup` object and assign it to the
switches using the `redundancy` field.

Example of switch configured for ESLAG:

```{.yaml .annotate linenums="1" title="SwitchGroup-Switch-example.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: SwitchGroup
metadata:
  name: eslag-1
  namespace: default
spec: {}
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: s5248-03
  namespace: default
spec:
  ...
  redundancy:
    group: eslag-1
    type: eslag
  ...
```

And example of switch configured for MCLAG:

```{.yaml .annotate linenums="1" title="MCLAG-switchgroup.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: SwitchGroup
metadata:
  name: mclag-1
  namespace: default
spec: {}
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Switch
metadata:
  name: s5248-01
  namespace: default
spec:
  ...
  redundancy:
    group: mclag-1
    type: mclag
  ...
```

In case of MCLAG it's required to have a special connection with type `mclag-domain` that defines the peer and session
links between switches. For more details, see [Connections](./connections.md).

## Servers

Regular workload server:

```{.yaml .annotate linenums="1" title="Server.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: Server
metadata:
  name: server-1
  namespace: default
spec:
  description: MH s5248-01/E1 s5248-02/E1
```
