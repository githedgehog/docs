# Adding Gateway Node

This guide covers adding a gateway node to an existing Fabric deployment. Gateway nodes provide advanced network services
(NAT, PAT, firewalling) by handling traffic between VPCs or between VPCs and externals using Gateway Peerings.

## Required Resources

Three types of resources must be created:

1. **FabNode** - Defines the gateway node at the fabricator level
2. **Gateway** - Defines gateway configuration in the fabric namespace
3. **Connection (type=gateway)** - Establishes uplinks to fabric switches

## Step 1: Gather Configuration Values

When adding a gateway to an existing Fabric, automatic IP hydration does not apply. You must manually allocate all IP
addresses and ASNs based on your existing subnet configuration.

Extract subnet information from `fab.yaml`:

* `config.control.managementSubnet` - Management network range
* `config.control.dummySubnet` - Dummy interface subnet
* `config.fabric.managementDHCPStart` - DHCP range start
* `config.fabric.protocolSubnet` - Protocol IP subnet
* `config.fabric.vtepSubnet` - VTEP IP subnet
* `config.fabric.fabricSubnet` - Fabric link IP subnet
* `config.gateway.asn` - Gateway ASN (typically 65534)

Example configuration:

```yaml
config:
  control:
    managementSubnet: 172.30.30.0/24
    dummySubnet: 172.30.50.0/24
  fabric:
    managementDHCPStart: 172.30.30.10
    protocolSubnet: 172.30.40.0/24
    vtepSubnet: 172.30.41.0/24
    fabricSubnet: 172.30.42.0/24
  gateway:
    asn: 65534
```

## Step 2: Allocate IP Addresses

Select unique IP addresses from the configured subnets:

### Management IP

Must be in management subnet, below DHCP start range:

```
If DHCP starts at 172.30.30.10, choose from 172.30.30.2-172.30.30.9
Example: 172.30.30.5/24
```

### Dummy IP

Unique /31 from dummy subnet:

```
Example: 172.30.50.4/31
```

Verify uniqueness by checking existing allocations:

```bash
kubectl get fabnodes -n fab -o yaml | grep "dummy:" -A 1
kubectl get controlnodes -n fab -o yaml | grep "dummy:" -A 1
```

### Protocol IP

Unique /32 from protocol subnet:

```
Example: 172.30.40.3/32
```

### VTEP IP

Unique /32 from VTEP subnet:

```
Example: 172.30.41.3/32
```

### Fabric Link IPs

Unique /31 pairs from fabric subnet (one pair per uplink):

```
Example for two uplinks:
- Spine-01 link: Switch 172.30.42.0/31, Gateway 172.30.42.1/31
- Spine-02 link: Switch 172.30.42.2/31, Gateway 172.30.42.3/31
```

Check existing fabric IPs:

```bash
kubectl get connections -o yaml | grep "ip:" | grep -v "vtepIP\|protocolIP"
```

## Step 3: Create FabNode Resource

Create `include/gateway-1-node.yaml` in your fabricator working directory:

```yaml
apiVersion: fabricator.githedgehog.com/v1beta1
kind: FabNode
metadata:
  name: gateway-1
spec:
  roles:
    - gateway
  bootstrap:
    disk: /dev/sda  # Adjust to match your hardware
  management:
    ip: 172.30.30.5/24  # Below DHCP start, from managementSubnet
    interface: enp1s0   # Management interface name on gateway hardware
  dummy:
    ip: 172.30.50.4/31  # Unique /31 from dummySubnet
```

## Step 4: Create Gateway Resource

Create `include/gateway-1.yaml`:

```yaml
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Gateway
metadata:
  name: gateway-1
  namespace: fab
spec:
  asn: 65534                 # Must match config.gateway.asn from fab.yaml
  protocolIP: 172.30.40.3/32 # Unique /32 from protocolSubnet
  vtepIP: 172.30.41.3/32     # Unique /32 from vtepSubnet
  interfaces:
    enp2s1: {}               # Interface for first uplink
    enp2s2: {}               # Interface for second uplink
  workers: 8                 # Dataplane worker threads
```

Interface names must match physical network interfaces on the gateway node. For kernel driver (default), use standard Linux
interface names (enp2s1, enp2s2, etc.). For DPDK driver, configure PCI addresses in the interfaces section.

## Step 5: Create Gateway Connections

Gateway connections establish uplinks to Fabric switches. For spine-leaf topology, connect to spines. For mesh topology,
connect to leaves.

!!! note "Mesh Topology Limitation"
    Gateway connections to TH5 leaf switches are not supported.

Add to `include/gateway-1.yaml`:

```yaml
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-01--gateway--gateway-1
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: spine-01/E1/8  # Physical port on spine switch
          ip: 172.30.42.0/31   # Unique /31 from fabricSubnet
        gateway:
          port: gateway-1/enp2s1  # Must match interface in Gateway spec
          ip: 172.30.42.1/31      # Pair with switch IP from fabricSubnet
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: spine-02--gateway--gateway-1
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: spine-02/E1/8
          ip: 172.30.42.2/31
        gateway:
          port: gateway-1/enp2s2
          ip: 172.30.42.3/31
```

Key points:

* Each link requires a /31 IP pair from fabricSubnet
* Gateway port must match an interface defined in the Gateway spec
* Switch port must be a valid port on the switch (see [Switch Profiles](profiles.md))
* Connection name follows pattern: `<switch>--gateway--<gateway>`

## Step 6: Validate Configuration

From the fabricator working directory:

```bash
hhfab validate
```

Fix any validation errors before proceeding.

## Step 7: Build Gateway Installer

Build the gateway node installer:

```bash
hhfab build --gateways
```

This creates a bootable ISO at `result/gateway-1.iso`.

## Step 8: Install Gateway Node

1. Boot the gateway node from the generated ISO using virtual media
2. Configure server for UEFI boot without secure boot
3. Installation proceeds automatically
4. System reboots automatically after installation
5. Remove installation media during reboot

For detailed installation steps, see [Install Gateway Node](../install-upgrade/install.md#install-gateway-node).

## Step 9: Verify Installation

Check gateway node status:

```bash
kubectl get nodes
```

Expected output:

```
NAME        STATUS   ROLES                AGE    VERSION
control-1   Ready    control-plane,etcd   2d2h   v1.34.1+k3s1
gateway-1   Ready    <none>               5m     v1.34.1+k3s1
```

Check Gateway resource:

```bash
kubectl get gateway -n fab
```

Expected output:

```
NAME        ASN     PROTOCOL IP      VTEP IP         AGE
gateway-1   65534   172.30.40.3/32   172.30.41.3/32  5m
```

Check FabNode:

```bash
kubectl get fabnode -n fab
```

Expected output:

```
NAME        ROLES         MGMTIP          AGE
gateway-1   ["gateway"]   172.30.0.6/21   5m
```
