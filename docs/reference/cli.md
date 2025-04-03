# Fabric CLI

!!! warning ""
    Under construction.

Currently Fabric CLI is represented by a kubectl plugin `kubectl-fabric` automatically installed on the Control Node.
It is a wrapper around `kubectl` and Kubernetes client which allows to manage Fabric resources in a more convenient way.
Fabric CLI only provides a subset of the functionality available via Fabric API and is focused on simplifying objects
creation and some manipulation with the already existing objects while main get/list/update operations are expected to
be done using `kubectl`.

```console
core@control-1 ~ $ kubectl fabric
NAME:
   kubectl fabric - Hedgehog Fabric API kubectl plugin

USAGE:
   kubectl fabric [global options] command [command options]

VERSION:
   v0.71.6

COMMANDS:
   vpc               VPC commands
   switch, sw        Switch commands
   connection, conn  Connection commands
   switchgroup, sg   SwitchGroup commands
   external, ext     External commands
   wiring            general wiring diagram helpers
   inspect, i        Inspect Fabric API Objects and Primitives
   help, h           Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --verbose, -v  verbose output (includes debug) (default: true)
   --help, -h     show help
   --version, -V  print the version
```

## VPC

Create VPC named `vpc-1` with subnet `10.0.1.0/24` and VLAN `1001` with DHCP enabled and DHCP range starting from
`10.0.1.10` (optional):

```bash
core@control-1 ~ $ kubectl fabric vpc create --name vpc-1 --subnet 10.0.1.0/24 --vlan 1001 --dhcp --dhcp-start 10.0.1.10
```

Attach previously created VPC to the server `server-01` (which is connected to the Fabric using the
`server-01--mclag--leaf-01--leaf-02` Connection):

```bash
core@control-1 ~ $ kubectl fabric vpc attach --vpc-subnet vpc-1/default --connection server-01--mclag--leaf-01--leaf-02
```

To peer VPC with another VPC (e.g. `vpc-2`) use the following command:

```bash
core@control-1 ~ $ kubectl fabric vpc peer --vpc vpc-1 --vpc vpc-2
```

## Inspect

The `kubectl fabric inspect` feature is a text representation the stats of the
relevant sub-command.

```bash
core@control-1 ~ $ kubectl fabric inspect
NAME:
   kubectl fabric inspect - Inspect Fabric API Objects and Primitives

USAGE:
   kubectl fabric inspect [command options]

COMMANDS:
   fabric                  Inspect Fabric (overall control nodes and switches overview incl. status, serials, etc.)
   switch                  Inspect Switch (status, used ports, counters, etc.)
   port, switchport        Inspect Switch Port (connection if used in one, counters, VPC and External attachments, etc.)
   server                  Inspect Server (connection if used in one, VPC attachments, etc.)
   connection, conn        Inspect Connection (incl. VPC and External attachments, Loobpback Workaround usage, etc.)
   vpc, subnet, vpcsubnet  Inspect VPC/VPCSubnet (incl. where is it attached and what's reachable from it)
   bgp                     Inspect BGP neighbors
   lldp                    Inspect LLDP neighbors
   ip                      Inspect IP Address (incl. IPv4Namespace, VPCSubnet and DHCPLease or External/StaticExternal usage)
   mac                     Inspect MAC Address (incl. switch ports and DHCP leases)
   access                  Inspect access between pair of IPs, Server names or VPCSubnets (everything except external IPs will be translated to VPCSubnets)
   help, h                 Shows a list of commands or help for one command

OPTIONS:
   --verbose, -v  verbose output (includes debug) (default: true)
   --help, -h     show help
```
