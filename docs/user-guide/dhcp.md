# DHCP

The Fabric includes an integrated DHCP server that dinamically assigns IP addresses to hosts connected to VPC subnets. The DHCP server supports dynamic IP allocation, static leases, and various configuration options.

## Overview

The DHCP server is configured per VPC subnet and provides:

- Dynamic IP allocation from a configurable range
- Static leases for specific MAC addresses
- DHCP options including DNS servers, NTP servers, PXE boot, MTU, and custom routes
- DHCP relay support for third-party DHCP servers

## Basic Configuration

### Enabling DHCP

To enable DHCP for a VPC subnet, set `dhcp.enable: true` in the subnet configuration:

```yaml title="vpc-with-dhcp.yaml"
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  subnets:
    default:
      subnet: 10.10.1.0/24
      gateway: 10.10.1.1
      vlan: 1001
      dhcp:
        enable: true
```

With this minimal configuration, the DHCP server will:

- Use all available IPs in the subnet (excluding the gateway)
- Provide a default lease time of 3600 seconds (1 hour)
- Configure the VPC gateway as the default route

### Specifying an IP Range

You can limit the DHCP pool to a specific range of IP addresses:

```yaml
dhcp:
  enable: true
  range:
    start: 10.10.1.10
    end: 10.10.1.99
```

This reserves IPs outside the range (e.g., `10.10.1.2-10.10.1.9` and `10.10.1.100-10.10.1.254`) for static assignments or other purposes.

### CLI Usage

Use the `kubectl fabric vpc create` command with DHCP options:

```bash
kubectl fabric vpc create \
  --name vpc-1 \
  --subnet 10.10.1.0/24 \
  --vlan 1001 \
  --dhcp \
  --dhcp-start 10.10.1.10
```

After creating the VPC, attach it to servers using their connection names:

```bash
kubectl fabric vpc attach \
  --vpc vpc-1 \
  --subnet default \
  --connection server-01--mclag--leaf-01--leaf-02
```

!!! note "CLI Limitations"
    The CLI does not currently support configuring static leases or advanced DHCP options. Use YAML configuration with `kubectl apply -f` for these features.

## DHCP Options

The DHCP server supports various options to customize network configuration for clients:

```yaml title="vpc-with-dhcp-options.yaml"
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  subnets:
    default:
      subnet: 10.10.1.0/24
      gateway: 10.10.1.1
      vlan: 1001
      dhcp:
        enable: true
        range:
          start: 10.10.1.10
          end: 10.10.1.99
        options:
          leaseTimeSeconds: 7200              # 2 hours
          dnsServers:
            - 1.1.1.1
            - 8.8.8.8
          timeServers:                        # NTP servers
            - 132.163.96.1
            - 132.163.96.2
          interfaceMTU: 9000                  # Jumbo frames
          pxeURL: tftp://10.10.10.99/bootfile # PXE boot server
          disableDefaultRoute: false          # Manage default route
          advertisedRoutes:                   # Custom static routes
            - destination: 10.20.0.0/16
              gateway: 10.10.1.2
            - destination: 10.30.0.0/16
              gateway: 10.10.1.3
```

### Option Details

| Option | Description | Default |
|--------|-------------|---------|
| `leaseTimeSeconds` | Duration of DHCP lease in seconds | 3600 |
| `dnsServers` | List of DNS server IP addresses | None |
| `timeServers` | List of NTP server IP addresses | None |
| `interfaceMTU` | MTU size for the interface (doesn't affect switch interfaces) | 9036 |
| `pxeURL` | PXE boot server URL (TFTP only, no HTTP query strings) | None |
| `disableDefaultRoute` | If true, don't send default route to clients | false |
| `advertisedRoutes` | Additional static routes sent via DHCP option 121 | None |

!!! note "Default Route Behavior"
    - By default, the DHCP server configures the VPC gateway as the default route
    - In L3VNI mode with `disableDefaultRoute: true`, routes to other VPC subnets are still sent
    - Custom routes in `advertisedRoutes` are always sent, regardless of `disableDefaultRoute`

## Static Leases

Static leases bind specific MAC addresses to predetermined IP addresses. This is useful for:

- Servers requiring consistent IP addresses
- Network equipment that needs fixed IPs
- Hosts that need IPs outside the dynamic range

Static leases can be configured in two ways:

1. Via VPC YAML - Configure static leases in the VPC subnet definition
2. Via DHCPSubnet resource - Directly modify the DHCPSubnet resource

### Method 1: Configuring Static Leases via VPC

```yaml title="vpc-with-static-leases.yaml"
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  subnets:
    default:
      subnet: 10.10.1.0/24
      gateway: 10.10.1.1
      vlan: 1001
      dhcp:
        enable: true
        range:
          start: 10.10.1.10
          end: 10.10.1.99
        static:
          "aa:bb:cc:dd:ee:01":
            ip: 10.10.1.5
          "aa:bb:cc:dd:ee:02":
            ip: 10.10.1.6
          "aa:bb:cc:dd:ee:03":
            ip: 10.10.1.100
```

Apply the configuration:

```bash
kubectl apply -f vpc-with-static-leases.yaml
```

### Method 2: Configuring Static Leases via DHCPSubnet

For advanced use cases, you can directly edit the DHCPSubnet resource. The DHCPSubnet is automatically created when you enable DHCP on a VPC subnet, with the name format `<vpc-name>--<subnet-name>`.

First, find the DHCPSubnet resource:

```bash
kubectl get dhcpsubnets.dhcp.githedgehog.com
```

Example output:

```
NAME                CIDR           START IP      END IP
vpc-1--default      10.10.1.0/24   10.10.1.10    10.10.1.99
```

View the current configuration:

```bash
kubectl get dhcpsubnets.dhcp.githedgehog.com vpc-1--default -o yaml
```

Edit the DHCPSubnet to add static leases:

```bash
kubectl edit dhcpsubnets.dhcp.githedgehog.com vpc-1--default
```

Add the static leases under `spec.static`:

```yaml
apiVersion: dhcp.githedgehog.com/v1beta1
kind: DHCPSubnet
metadata:
  name: vpc-1--default
  namespace: default
spec:
  subnet: vpc-1/default
  cidrBlock: 10.10.1.0/24
  gateway: 10.10.1.1
  startIP: 10.10.1.10
  endIP: 10.10.1.99
  vrf: VrfVvpc-1
  circuitID: Vlan1001
  leaseTimeSeconds: 3600
  static:                           # Add static leases here
    "aa:bb:cc:dd:ee:01":
      ip: 10.10.1.5
    "aa:bb:cc:dd:ee:02":
      ip: 10.10.1.6
    "aa:bb:cc:dd:ee:03":
      ip: 10.10.1.100
```

Alternatively, use `kubectl patch`:

```bash
kubectl patch dhcpsubnets.dhcp.githedgehog.com vpc-1--default --type=merge -p '
{
  "spec": {
    "static": {
      "aa:bb:cc:dd:ee:01": {"ip": "10.10.1.5"},
      "aa:bb:cc:dd:ee:02": {"ip": "10.10.1.6"}
    }
  }
}'
```

!!! warning "VPC vs DHCPSubnet Configuration"
    - Changes made to the VPC YAML will overwrite static leases configured directly in DHCPSubnet
    - It's recommended to choose one method and stick with it to avoid configuration conflicts
    - The VPC method is preferred for most use cases as it keeps configuration centralized

## Managing Static Leases

### Adding a Static Lease

To add a new static lease to an existing VPC:

Method 1: Update VPC YAML

```bash
kubectl get vpc vpc-1 -o yaml > vpc-1.yaml
# Edit vpc-1.yaml to add static lease under spec.subnets.<subnet>.dhcp.static
kubectl apply -f vpc-1.yaml
```

Method 2: Patch DHCPSubnet

```bash
kubectl patch dhcpsubnets.dhcp.githedgehog.com vpc-1--default --type=merge -p '
{
  "spec": {
    "static": {
      "aa:bb:cc:dd:ee:04": {"ip": "10.10.1.7"}
    }
  }
}'
```

### Removing a Static Lease

Method 1: Update VPC YAML

Edit the VPC YAML and remove the MAC address entry from `spec.subnets.<subnet>.dhcp.static`, then apply.

Method 2: Patch DHCPSubnet

```bash
kubectl patch dhcpsubnets.dhcp.githedgehog.com vpc-1--default --type=json -p '
[
  {
    "op": "remove",
    "path": "/spec/static/aa:bb:cc:dd:ee:01"
  }
]'
```

### Changing a Static IP

To change the IP for an existing MAC address, update the entry:

```bash
kubectl patch dhcpsubnets.dhcp.githedgehog.com vpc-1--default --type=merge -p '
{
  "spec": {
    "static": {
      "aa:bb:cc:dd:ee:01": {"ip": "10.10.1.15"}
    }
  }
}'
```

After changing a static IP, the client will need to release and renew its DHCP lease:

```bash
# On the client host
sudo networkctl reconfigure <interface>
```

## Third-Party DHCP Servers

Instead of using the integrated DHCP server, you can configure DHCP relay to use an external DHCP server:

```yaml
apiVersion: vpc.githedgehog.com/v1beta1
kind: VPC
metadata:
  name: vpc-1
  namespace: default
spec:
  subnets:
    default:
      subnet: 10.10.1.0/24
      gateway: 10.10.1.1
      vlan: 1001
      dhcp:
        relay: 10.99.0.100  # IP of external DHCP server
```

!!! note "External DHCP Server Access"
    The external DHCP server must be reachable from the fabric. Use a [StaticExternal connection](connections.md#staticexternal) to provide connectivity to the DHCP server.
