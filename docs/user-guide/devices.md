# Switches and Servers

All devices in the Hedgehog Fabric are divided into two groups: switches and servers and represented by corresponding
`Switch` and `Server` objects in the API. It's needed to define all participants of the Fabric and their roles in the
Wiring Diagram as well as [Connections](./connections.md) between them.

## Switches

Switches are the main building blocks of the Fabric. They are represented by `Switch` objects in the API and consists
of the basic information like name, description, location, role, etc. as well as port group speeds, port breakouts, ASN,
IP addresses and etc.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Switch
metadata:
  name: s5248-01
  namespace: default
spec:
  asn: 65101 # ASN of the switch
  description: leaf-1
  ip: 172.30.10.100/32 # Switch IP that will be accessible from the Control Node
  location:
    location: gen--default--s5248-01
  locationSig:
    sig: <undefined>
    uuidSig: <undefined>
  portBreakouts: # Configures port breakouts for the switch
    1/55: 4x25G
  portGroupSpeeds: # Configures port group speeds for the switch
    "1": 10G
    "2": 10G
  protocolIP: 172.30.11.100/32 # Used as BGP router ID
  role: server-leaf # Role of the switch, one of server-leaf, border-leaf and mixed-leaf
  vlanNamespaces: # Defines which VLANs could be used to attach servers
  - default
  vtepIP: 172.30.12.100/32
  groups: # Defines which groups the switch belongs to
  - some-group
```

The `SwitchGroup` is just a marker at that point and doesn't have any configuration options.

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: SwitchGroup
metadata:
  name: border
  namespace: default
spec: {}
```

## Servers

It includes both control nodes and user's workload servers.

Control Node:

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Server
metadata:
  name: control-1
  namespace: default
spec:
  type: control # Type of the server, one of control or "" (empty) for regular workload server
```

Regular workload server:

```yaml
apiVersion: wiring.githedgehog.com/v1alpha2
kind: Server
metadata:
  name: server-1
  namespace: default
spec:
  description: MH s5248-01/E1 s5248-02/E1
```
