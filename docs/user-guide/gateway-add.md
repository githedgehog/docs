# Adding Gateways to the fabric

This section covers adding a gateway node to an existing Fabric. Gateway nodes provide advanced network services (NAT, PAT, firewalling) by
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

3. **FabNode** - Defines the gateway node at the fabricator level (required for `hhfab build --gateways`). See [Install Gateway Node](../install-upgrade/install.md#install-gateway-node) for details on installing the bare metal machine.

## Step 1: Gather Configuration Values

Extract subnet information from the Fabricator configuration:

* `config.control.managementSubnet` - Management network range
* `config.control.dummySubnet` - Dummy interface subnet
* `config.fabric.managementDHCPStart` - DHCP range start
* `config.fabric.protocolSubnet` - Protocol IP subnet
* `config.fabric.vtepSubnet` - VTEP IP subnet
* `config.fabric.fabricSubnet` - Fabric link IP subnet

Example configuration:

```yaml
config:
  control:
    managementSubnet: 172.30.0.0/21
    controlVIP: 172.30.0.1
    dummySubnet: 172.30.90.0/24
  fabric:
    managementDHCPStart: 172.30.4.0
    protocolSubnet: 172.30.8.0/24
    vtepSubnet: 172.30.12.0/24
    fabricSubnet: 172.30.128.0/24
```

The ASN of the gateway comes from the [fabric domain](multi-fabric.md#fabrics-and-domains) it belongs to;
for the default fabric and domain this will typically be 65534, and it can be retrieved with:

```bash
kubectl get fabrics default -o jsonpath='{.spec.domains.default.gatewayASN}'
```

!!! note
    The Fabricator configuration field `config.gateway.asn` is deprecated, and it is only used to seed
    Fabric/default when upgrading from an older version.

## Step 2: Allocate IP Addresses

Select unique IP addresses from the configured subnets:

### Management IP

The management IP provides connectivity to the gateway node for SSH access and cluster communication. It must be:

* In the management subnet (`config.control.managementSubnet`)
* Below the DHCP start range (`config.fabric.managementDHCPStart`)
* Not the control VIP or already assigned to another node

To safely choose a management IP, check existing allocations:

List all control nodes with their management IPs:

```bash
kubectl get controlnodes -n fab -o custom-columns=NAME:.metadata.name,MGMT_IP:.spec.management.ip,DUMMY_IP:.spec.dummy.ip
```

List all gateway nodes with their management IPs:

```bash
kubectl get fabnodes -n fab -o custom-columns=NAME:.metadata.name,MGMT_IP:.spec.management.ip,DUMMY_IP:.spec.dummy.ip
```

Check the control VIP:

```bash
kubectl get fabricator -n fab -o jsonpath='{.items[0].spec.config.control.controlVIP}'
```

Example: If management subnet is 172.30.0.0/21 and DHCP starts at 172.30.4.0, choose from 172.30.0.2 through 172.30.3.254
(avoiding 172.30.0.1 which is typically the control VIP).

### Dummy IP

The dummy IP is used for internal K3s cluster communication between control and gateway nodes. We use dummy network devices
and IPs to ensure K3s has a stable default network route. Each node requires a unique /31 subnet from the dummy subnet range.
The /31 provides a point-to-point link between the node and the control plane.

Verify uniqueness by checking existing allocations:

Check control node dummy IPs:

```bash
kubectl get controlnodes -n fab -o custom-columns=NAME:.metadata.name,DUMMY_IP:.spec.dummy.ip
```

Check gateway node dummy IPs:

```bash
kubectl get fabnodes -n fab -o custom-columns=NAME:.metadata.name,DUMMY_IP:.spec.dummy.ip
```

Example: If dummy subnet is 172.30.90.0/24, and control-1 uses 172.30.90.0/31, choose 172.30.90.2/31 for gateway-1.

### Protocol IP

Unique /32 from protocol subnet (`config.fabric.protocolSubnet`).

Example: 172.30.8.3/32 (from 172.30.8.0/24)

### VTEP IP

Unique /32 from VTEP subnet (`config.fabric.vtepSubnet`).

Example: 172.30.12.3/32 (from 172.30.12.0/24)

### Fabric Link IPs

Unique /31 pairs from fabric subnet (`config.fabric.fabricSubnet`, one pair per uplink).

Example for two uplinks (from 172.30.128.0/24):
- Leaf-01 link: Switch 172.30.128.0/31, Gateway 172.30.128.1/31
- Leaf-02 link: Switch 172.30.128.10/31, Gateway 172.30.128.11/31

Check existing gateway connection IPs:

```bash
kubectl get connections -o custom-columns=NAME:.metadata.name,SWITCH_IP:.spec.gateway.links[0].switch.ip,GW_IP:.spec.gateway.links[0].gateway.ip 2>/dev/null | grep gateway
```

## Step 3: Create Gateway Connections

Gateway connections must be created before the Gateway resource. Connections establish uplinks to Fabric switches and define
the IP addresses used by gateway interfaces. For spine-leaf topology, connect to spines. For mesh topology, connect to leaves.

Create a YAML file with your Connection resources:

```{.yaml .annotate linenums="1" title="gateway-connections.yaml"}
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: leaf-01--gateway--gateway-1 # (1)!
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: leaf-01/E1/8 # (2)!
          ip: 172.30.128.0/31 # (3)!
        gateway:
          port: gateway-1/port1 # (4)!
          ip: 172.30.128.1/31 # (5)!
---
apiVersion: wiring.githedgehog.com/v1beta1
kind: Connection
metadata:
  name: leaf-02--gateway--gateway-1 # (6)!
  namespace: default
spec:
  gateway:
    links:
      - switch:
          port: leaf-02/E1/9 # (7)!
          ip: 172.30.128.10/31 # (8)!
        gateway:
          port: gateway-1/port2 # (9)!
          ip: 172.30.128.11/31 # (10)!
```

1. Connection name - we typically use the pattern `<switch>--gateway--<gateway>` but any name will work
2. Switch port must be a valid port on the switch (see [Switch Profiles](profiles.md))
3. Allocate a unique /31 IP from `config.fabric.fabricSubnet` for the switch side
4. Gateway port name, any name unique within the gateway, it is defined in the Gateway resource `interfaces`
5. Allocate the paired /31 IP from `config.fabric.fabricSubnet` for the gateway side
6. Connection name for the second uplink
7. Switch port for the second uplink
8. Allocate another unique /31 IP pair from `config.fabric.fabricSubnet` for the switch side
9. Gateway port name for the second uplink
10. Allocate the paired /31 IP for the gateway side

Apply the Connection resources to the cluster:

```bash
kubectl apply -f gateway-connections.yaml
```

!!! note
    Connections must be created in the `default` namespace and must be applied before the Gateway resource.

## Step 4: Create Gateway Resource

After Connections are created, create the Gateway resource. The Gateway resource requires interface IPs and BGP neighbor
information derived from the Connections.

First, determine the BGP ASNs of the switches you're connecting to:

```bash
kubectl get switches -o custom-columns=NAME:.metadata.name,ASN:.spec.asn
```

Create a YAML file with your Gateway resource:

```{.yaml .annotate linenums="1" title="gateway.yaml"}
apiVersion: gateway.githedgehog.com/v1alpha1
kind: Gateway
metadata:
  name: gateway-1
  namespace: fab
spec:
  asn: 65534 # (1)!
  protocolIP: 172.30.8.3/32 # (2)!
  vtepIP: 172.30.12.3/32 # (3)!
  vtepMAC: 02:00:00:00:01:02 # (4)!
  driver: dpdk # (5)!
  interfaces:
    port1: # (6)!
      pci: "0000:02:01.0" # (7)!
      kernel: enp2s1 # (8)!
      ips:
        - 172.30.128.1/31 # (9)!
    port2: # (10)!
      pci: "0000:02:02.0" # (11)!
      kernel: enp2s2 # (12)!
      ips:
        - 172.30.128.11/31 # (13)!
  neighbors:
    - asn: 65101 # (14)!
      ip: 172.30.128.0 # (15)!
      source: port1 # (16)!
    - asn: 65102 # (17)!
      ip: 172.30.128.10 # (18)!
      source: port2 # (19)!
  workers: 28 # (20)!
```

1. Must match the `gatewayASN` of the gateway's [fabric and domain](multi-fabric.md#fabrics-and-domains);
   for the default case, get it from `kubectl get fabrics default -o jsonpath='{.spec.domains.default.gatewayASN}'`
2. Allocate a unique /32 from `config.fabric.protocolSubnet` (BGP router ID)
3. Allocate a unique /32 from `config.fabric.vtepSubnet` (VXLAN tunnel endpoint)
4. MAC address for VTEP - any valid MAC address (e.g., 02:00:00:00:01:02)
5. Dataplane driver, `dpdk` is recommended, see [Dataplane Driver](#dataplane-driver)
6. Port name, any name unique within the gateway, must match the `gateway.port` in the Connection resource
7. PCI address of the NIC port on the gateway node, required with the `dpdk` driver
8. Linux kernel interface name of the NIC port, only used by the `kernel` driver (defaults to the port name)
9. Must match the `gateway.ip` from the corresponding Connection resource (gateway-connections.yaml line 14)
10. Port name for the second uplink
11. PCI address of the NIC port for the second uplink
12. Linux kernel interface name of the NIC port for the second uplink
13. Must match the `gateway.ip` from the corresponding Connection resource (gateway-connections.yaml line 29)
14. Switch ASN - get from `kubectl get switches -o custom-columns=NAME:.metadata.name,ASN:.spec.asn` for leaf-01
15. Must match the `switch.ip` from the corresponding Connection resource (gateway-connections.yaml line 11)
16. Must match the port name defined above
17. Switch ASN for the second uplink - get from `kubectl get switches` for leaf-02
18. Must match the `switch.ip` from the corresponding Connection resource (gateway-connections.yaml line 26)
19. Must match the port name for the second uplink
20. Number of dataplane worker threads, see [Workers](#workers)

Apply the Gateway resource to the cluster:

```bash
kubectl apply -f gateway.yaml
```

### Dataplane Driver

The `driver` field selects how the dataplane accesses the gateway NICs:

* `dpdk` is the main and recommended driver: the dataplane takes over the NICs, identified by the `pci` address of each
  port.
* `kernel` uses the Linux kernel network interfaces, identified by the `kernel` name of each port, and it is mainly
  intended for testing. If `driver` is not set, `kernel` is used.

The name of each port (the key in `interfaces`) is what the Connections (`gateway-1/port1`) and the BGP neighbors
(`source`) refer to. The `kernel` field is the Linux kernel interface name of the NIC port and it's only used by the
`kernel` driver; if it's not set, the port name is used as the kernel interface name. So with the `dpdk` driver, or
with `kernel` set, the port name could be anything unique within the gateway, and keeping both `pci` and `kernel` set
allows switching between the drivers.

To find the PCI addresses and kernel interface names of all NIC ports, run on the gateway node:

```console
core@gateway-1 ~ $ sudo lshw -c network -businfo
Bus info          Device     Class      Description
===================================================
pci@0000:01:00.0  enp1s0     network    Ethernet Controller I225-LM
pci@0000:02:01.0  enp2s1     network    MT2910 Family [ConnectX-7]
pci@0000:02:02.0  enp2s2     network    MT2910 Family [ConnectX-7]
```

The PCI address is the `Bus info` without the `pci@` prefix, e.g. `0000:02:01.0`, and the kernel interface name is the
`Device`, e.g. `enp2s1`.

With the `dpdk` driver, the NICs used by the dataplane are not visible to host tools such as `ip` or `tcpdump` while the
dataplane is running, see [Capturing Packets](../troubleshooting/gateway.md#capturing-packets) for an alternative.

#### Switching an Existing Gateway to DPDK

Gateways created before 26.05 without `pci` addresses keep using the `kernel` driver after the upgrade, with the port
names being the kernel interface names, e.g. `enp2s1`. To switch such a gateway to the `dpdk` driver, add the `pci`
address of each port and set `driver: dpdk`, while keeping the port names, so the Connections and BGP neighbors don't
need to change:

```yaml
spec:
  driver: dpdk
  interfaces:
    enp2s1:
      pci: "0000:02:01.0"
      ips:
        - 172.30.128.1/31
    enp2s2:
      pci: "0000:02:02.0"
      ips:
        - 172.30.128.11/31
```

The dataplane restarts with the new driver, so traffic through the gateway is interrupted for a short time; switch
the gateways of a group one at a time.

### Workers

The `workers` field is the number of dataplane worker threads, 4 by default and up to 64. Set it to the number of
physical CPU cores of the gateway node minus 2 to 4 cores left for the system and the control plane, e.g. 28 workers
for a gateway node with 32 physical cores. SMT (Hyper-Threading) threads don't count as cores.

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
