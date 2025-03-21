
# Fabric CLI Reference

Currently Fabric CLI is represented by a kubectl plugin `kubectl-fabric` automatically installed on the Control Node.
It is a wrapper around `kubectl` and Kubernetes client which allows to manage Fabric resources in a more convenient way.
Fabric CLI only provides a subset of the functionality available via Fabric API and is focused on simplifying objects
creation and some manipulation with the already existing objects while main get/list/update operations are expected to
be done using `kubectl`.

## Usage

```bash
core@control-1 ~ $ kubectl fabric
NAME:
   kubectl fabric - Hedgehog Fabric API kubectl plugin

USAGE:
   kubectl fabric [global options] command [command options]

VERSION:
   v0.53.1

COMMANDS:
   vpc               VPC commands
   switch, sw        Switch commands
   connection, conn  Connection commands
   switchgroup, sg   SwitchGroup commands
   external, ext     External commands
   inspect, i        Inspect Fabric API Objects and Primitives
   help, h           Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --verbose, -v  verbose output (includes debug) (default: true)
   --help, -h     show help
   --version, -V  print the version
```

## Commands and Options

| Command | Subcommand | Options | Description |
|---------|------------|---------|-------------|
| **vpc** | create | `--name`, `--subnet` (required), `--vlan` (required), `--dhcp`, `--dhcp-range-start`, `--dhcp-range-end`, `--print` | Create a new VPC. |
|  | attach | `--name`, `--vpc-subnet` (required), `--connection` (required), `--print` | Attach VPC to a server connection. |
|  | peer | `--name`, `--vpc` (required), `--remote`, `--print` | Peer two VPCs. |
|  | wipe | `--yes` | Delete all VPCs and peerings. |
| **switch** | ip | `--name`, `--username`, `--verbose` | Get switch management IP address. |
|  | ssh | `--name`, `--username`, `--verbose` | SSH into the switch. |
|  | serial | `--name`, `--username`, `--verbose` | Run serial console for the switch. |
|  | reboot | `--name`, `--yes`, `--verbose` | Reboot the switch. |
|  | power-reset | `--name`, `--yes`, `--verbose` | Power reset the switch. |
|  | reinstall | `--name`, `--yes`, `--verbose` | Reinstall the switch. |
| **connection** | get | `--type` | Get details of existing connections. |
| **switchgroup** | create | `--name`, `--print` | Create a new switch group. |
| **external** | create | `--name`, `--ipv4-namespace`, `--inbound-community`, `--outbound-community`, `--print` | Create a new external connection. |
|  | peer | `--vpc`, `--external`, `--vpc-subnet`, `--external-prefix`, `--print` | Peer external and VPC. |
| **wiring** | export | `--vpcs`, `--externals`, `--switch-profiles` | Export wiring diagram. |
| **inspect** | fabric | `--verbose`, `--output` (default: "text") | Inspect overall Fabric state. |
|  | switch | `--name`, `--output` (default: "text") | Inspect switch status and ports. |
|  | port | `--name`, `--output` (default: "text") | Inspect switch port status. |
|  | server | `--name`, `--output` (default: "text") | Inspect server status. |
|  | connection | `--name`, `--output` (default: "text") | Inspect connection details. |
|  | vpc | `--name`, `--subnet`, `--output` (default: "text") | Inspect VPC details. |
|  | bgp | `--switch-name`, `--strict` | Inspect BGP neighbors. |
|  | lldp | `--switch-name`, `--strict`, `--fabric`, `--external`, `--server` | Inspect LLDP neighbors. |
|  | ip | `--address` | Inspect IP details. |
|  | mac | `--address` | Inspect MAC details. |
|  | access | `--source`, `--destination` | Inspect connectivity. |

---

## Command Details

### `vpc`
VPC management commands.

#### `create`
Create a VPC:

```bash
kubectl fabric vpc create --name vpc-1 --subnet 10.0.1.0/24 --vlan 1001 --dhcp --dhcp-start 10.0.1.10 --dhcp-end 10.0.1.100
```


**Options:**

- `--name` – VPC name.
- `--subnet` – Subnet in CIDR format (**required**).
- `--vlan` – VLAN ID (**required**).
- `--dhcp` – Enable DHCP.
- `--dhcp-range-start` – Start of DHCP range.
- `--dhcp-range-end` – End of DHCP range.
- `--print` – Print object as YAML.

#### `attach`
Attach a VPC to a connection:

```bash
kubectl fabric vpc attach --vpc-subnet vpc-1/default --connection server-01
```


**Options:**

- `--vpc-subnet` – VPC subnet name (**required**).
- `--connection` – Connection name (**required**).

#### `peer`
Create a peering between VPCs:

```bash
kubectl fabric vpc peer --vpc vpc-1 --vpc vpc-2
```


**Options:**

- `--vpc` – VPC names (**required**).

#### `wipe`
Delete all VPCs:

```bash
kubectl fabric vpc wipe --yes
```


**Options:**
- `--yes` – Confirm deletion.

---

### `switch`
Switch management commands.

#### `ip`
Get switch IP:

```bash
kubectl fabric switch ip --name switch-01
```


**Options:**

- `--name` – Switch name.
- `--username` – SSH username (default: "admin").

#### `reboot`
Reboot the switch:

```bash
kubectl fabric switch reboot --name switch-01 --yes
```


**Options:**

- `--name` – Switch name.
- `--yes` – Confirm reboot.

---

### `connection`
Get connection details:

```bash
kubectl fabric connection get management
```


**Options:**

- `--type` – Connection type (`management`, `fabric`, `vpc-loopback`).

---

### `switchgroup`
Create a switch group:

```bash
kubectl fabric switchgroup create --name sg-01
```


**Options:**

- `--name` – Switch group name.

---

### `external`
Create an external connection:

```bash
kubectl fabric external create --name ext-01 --ipv4-namespace default
```


**Options:**

- `--name` – External name.
- `--ipv4-namespace` – IPv4 namespace.

---

### `wiring`
Export wiring diagram:

```bash
kubectl fabric wiring export --vpcs --externals
```


**Options:**

- `--vpcs` – Include VPCs (default: true).
- `--externals` – Include externals (default: true).

---

### `inspect`
Inspect Fabric objects:

```bash
kubectl fabric inspect fabric --output text
```


**Options:**

- `--output` – Output format (`text`, `yaml`, `json`).

---

## Global Options
- `--verbose`, `-v` – Enable verbose output (includes debug).
- `--help`, `-h` – Show help.
- `--version`, `-V` – Display version information.
- `--yes`, `-y` – Confirm potentially dangerous actions.

