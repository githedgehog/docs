# Adding Gateway Node

Adding a gateway node to an existing Fabric. Gateway nodes provide advanced network services (NAT, PAT, firewalling) by
handling traffic between VPCs or between VPCs and externals using Gateway Peerings.

## Understanding IP Allocation and Hydration

When building a new Fabric from scratch, IP addresses and ASNs can be automatically allocated through **hydration** - a process
that fills in missing IP addresses and ASNs based on configured subnets. However, **hydration does not work when adding resources
to an already running Fabric**. The Kubernetes admission webhooks require all IP addresses to be present and valid when creating
resources, preventing the use of hydration for incremental additions.

This means when adding a gateway to an existing deployment, you must manually:

* Select unique IP addresses from configured subnets
* Determine BGP ASNs for gateway neighbors
* Ensure no IP or ASN conflicts with existing resources

## Required Resources

Two types of resources must be created in the running cluster:

1. **Connection (type=gateway)** - Establishes uplinks to Fabric switches (must be created first)
2. **Gateway** - Defines gateway configuration in the fabric namespace (created after Connections)

Additionally, for building the gateway installer:

3. **FabNode** - Defines the gateway node at the fabricator level (required for `hhfab build --gateways`)

## Step 1: Gather Configuration Values

Extract subnet information from the Fabricator configuration:

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

The management IP provides connectivity to the gateway node for SSH access and cluster communication. It must be:

* In the management subnet (`config.control.managementSubnet`)
* Below the DHCP start range (`config.fabric.managementDHCPStart`)
* Not the control VIP or already assigned to another node

To safely choose a management IP, check existing allocations:

```bash
# List all control and gateway nodes with their management IPs
kubectl get controlnodes -n fab -o yaml | grep "ip:" -A 1
kubectl get fabnodes -n fab -o yaml | grep "ip:" -A 1

# Check the control VIP
kubectl get fabricator -n fab -o yaml | grep controlVIP
```

Example: If management subnet is 172.30.0.0/21 and DHCP starts at 172.30.4.0, choose from 172.30.0.2 through 172.30.3.254
(avoiding 172.30.0.1 which is typically the control VIP).

### Dummy IP

The dummy IP is used for internal K3s cluster communication between control and gateway nodes. Each node requires a unique /31
subnet from the dummy subnet range. The /31 provides a point-to-point link between the node and the control plane.

Verify uniqueness by checking existing allocations:

```bash
kubectl get fabnodes -n fab -o yaml | grep "dummy:" -A 1
kubectl get controlnodes -n fab -o yaml | grep "dummy:" -A 1
```

Example: If dummy subnet is 172.30.90.0/24, and control-1 uses 172.30.90.0/31, choose 172.30.90.2/31 for gateway-1.

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

## Step 3: Create Gateway Connections

Gateway connections must be created before the Gateway resource. Connections establish uplinks to Fabric switches and define
the IP addresses used by gateway interfaces. For spine-leaf topology, connect to spines. For mesh topology, connect to leaves.

!!! note "Mesh Topology Limitation"
    Gateway connections to TH5 leaf switches are not supported.

Apply the Connection resources to the cluster:

```bash
kubectl apply -f - <<'EOF'
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: leaf-01--gateway--gateway-1
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: leaf-01/E1/8
          ip: 172.30.128.0/31
        gateway:
          port: gateway-1/enp2s1
          ip: 172.30.128.1/31
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: leaf-02--gateway--gateway-1
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: leaf-02/E1/9
          ip: 172.30.128.10/31
        gateway:
          port: gateway-1/enp2s2
          ip: 172.30.128.11/31
EOF
```

Key points:

* Each link requires a /31 IP pair from fabricSubnet
* Gateway port names will be referenced in the Gateway resource
* Switch port must be a valid port on the switch (see [Switch Profiles](profiles.md))
* Connection name follows pattern: `<switch>--gateway--<gateway>`
* Connections must be in `default` namespace

## Step 4: Create Gateway Resource

After Connections are created, create the Gateway resource. The Gateway resource requires interface IPs and BGP neighbor
information derived from the Connections.

First, determine the BGP ASNs of the switches you're connecting to:

```bash
kubectl get switches -o yaml | grep -E "name: (leaf|spine)" -A 2 | grep asn
```

Then apply the Gateway resource:

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Gateway
metadata:
  name: gateway-1
  namespace: fab
spec:
  asn: 65534
  protocolIP: 172.30.8.3/32
  vtepIP: 172.30.12.3/32
  vtepMAC: CA:FE:BA:BE:01:02
  interfaces:
    enp2s1:
      ips:
        - 172.30.128.1/31
    enp2s2:
      ips:
        - 172.30.128.11/31
  neighbors:
    - asn: 65101
      ip: 172.30.128.0
      source: enp2s1
    - asn: 65102
      ip: 172.30.128.10
      source: enp2s2
  workers: 8
EOF
```

Key fields:

* `asn` - Must match `config.gateway.asn` from Fabricator configuration (typically 65534)
* `protocolIP` - Unique /32 from protocol subnet for BGP router ID
* `vtepIP` - Unique /32 from VTEP subnet for VXLAN tunnel endpoint
* `vtepMAC` - MAC address for VTEP (use format CA:FE:BA:BE:XX:XX with unique last two octets)
* `interfaces` - Each interface must have IPs matching the gateway side of the Connections
* `neighbors` - BGP neighbors with switch ASNs and IPs from switch side of Connections
* `workers` - Number of dataplane worker threads (typically 8)

The interface names (enp2s1, enp2s2) must match physical network interfaces on the gateway hardware. For kernel driver
(default), use standard Linux interface names. For DPDK driver, configure PCI addresses.

## Installing the Gateway Node

If the gateway node hardware is not yet installed, you need to create a FabNode resource and build the installer ISO. If the
gateway node is already running and joined to the cluster, skip to the Verification section.

### Create FabNode Resource

The FabNode resource defines the gateway node for the fabricator and is required to build the installer. Add it to your
fabricator configuration in `include/gateway-1-node.yaml`:

```yaml
apiVersion: fabricator.githedgehog.com/v1beta1
kind: FabNode
metadata:
  name: gateway-1
  namespace: fab
spec:
  roles:
    - gateway
  bootstrap:
    disk: /dev/sda
  management:
    ip: 172.30.0.6/21
    interface: enp2s0
  dummy:
    ip: 172.30.90.2/31
```

### Build and Install

From the fabricator working directory:

```bash
hhfab build --gateways
```

This creates a bootable ISO at `result/gateway-1.iso`. Follow the [Install Gateway Node](../install-upgrade/install.md#install-gateway-node)
guide to boot the gateway hardware from the ISO and complete installation.

## Verification

After creating the Gateway resource, verify it was created successfully:

```bash
kubectl get gateway -n fab -o wide
```

Expected output:

```
NAME        PROTOIP         VTEPIP           AGE
gateway-1   172.30.8.3/32   172.30.12.3/32   10s
```

Check that BGP sessions are established (may take a few moments):

```bash
kubectl get gateway -n fab -o yaml | grep -A 5 "status:"
```

Verify the gateway node joined the Kubernetes cluster:

```bash
kubectl get nodes
```

Expected output showing the gateway node:

```
NAME        STATUS   ROLES                AGE    VERSION
control-1   Ready    control-plane,etcd   2d2h   v1.34.1+k3s1
gateway-1   Ready    <none>               5m     v1.34.1+k3s1
```
