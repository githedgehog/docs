# Overview

## Inspecting the Fabric

The `kubectl fabric` plugin has an `inspect` functionality that shows an
overview of the fabric. `kubectl fabric inspect fabric` also shows detailed
information that is useful when diagnosing problems. To run the inspect
command:

```console
core@control-1 ~ $ kubectl fabric inspect fabric
Switches:
NAME        PROFILE           ROLE           GROUPS     SERIAL                 STATE    GEN    APPLIED           HEARTBEAT
leaf-01     Virtual Switch    server-leaf    eslag-1    0000000000000000000    Ready    1/1    10 minutes ago    22 seconds ago
leaf-02     Virtual Switch    server-leaf    eslag-1    0000000000000000000    Ready    1/1    21 minutes ago    19 seconds ago
leaf-03     Virtual Switch    server-leaf               0000000000000000000    Ready    1/1    38 minutes ago    10 seconds ago
spine-01    Virtual Switch    spine                     0000000000000000000    Ready    1/1    15 minutes ago    10 seconds ago
spine-02    Virtual Switch    spine                     0000000000000000000    Ready    1/1    45 minutes ago    24 seconds ago
```

The output above is from the virtual testing environment. In a deployment of physical
switches, the profile would match the profile of the switch, and the correct
serial number would be displayed.

The `GROUP` column will be populated if you have redundancy configured on the
switches, such as ESLAG (EVPN Multi-Homing).

The `GEN` column shows the applied/current generation. If the numbers are equal
then there are no pending changes for the switches.

The `APPLIED` column shows the amount of time since the last change was applied.

The `HEARTBEAT` column shows the amount of time since the controller received a
heartbeat from the switch. In normal operation, the value in this column will be less
than 60 seconds.


The output of the commands can also be formatted as json or yaml. To see all the options available use:

```console
core@control-1 ~ $ kubectl fabric inspect --help
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
