# Fabric CLI

!!! warning ""
    Under construction.

Currently Fabric CLI is represented by a kubectl plugin `kubectl-fabric` automatically installed on the Control Node.
It is a wrapper around `kubectl` and Kubernetes client which allows to manage Fabric resources in a more convenient way.
Fabric CLI only provides a subset of the functionality available via Fabric API and is focused on simplifying objects
creation and some manipulation with the already existing objects while main get/list/update operations are expected to
be done using `kubectl`.

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
