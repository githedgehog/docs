# Grafana Dashboards

To provide monitoring for most critical metrics from the switches managed by Hedgehog Fabric there are several Dashboards that may be used in Grafana deployments. Make sure that you've enabled metrics and logs collection for the switches in the Fabric that is
described in [Fabric Config](../install-upgrade/config.md#forward-switch-metrics-and-logs) section.

## Variables
List of common variables used in Hedgehog Grafana dashboards

- **env** (Label: Env): `label_values(env)` - Environment to monitor
- **node** (Label: Switch): `label_values(hostname)` - Switch Name
- **vrf** (Label: VRF): `label_values(vrf)` - VRF name (Multi-value)
- **neighbor** (Label: Neighbor): `label_values(neighbor)` - BGP Neighbor IP address(Multi-value)
- **interface** (Label: Interface): `label_values(interface)` - Switch Interface name as defined in wiring (Multi-value)
- **file** (Label: File): `label_valuse(filename)` - Name of Logs file to inspect (Loki)

## Switch Critical Resources

![Example](./boards/ASIC-Critical-Resourses-stats.png) 


This table reports usage and capacity of ASIC's programmable resources 
such as:

- ACLs
- IPv4 Routes
- IPv4 Nexthops
- IPv4 Neihbours
- IPMC Table
- FDB

[JSON](./boards/grafana_crm.json)

## Fabric

![Example](./boards/BGP-Fabric-stats.png) 

Fabric underlay and external peering monitoring. Including reporing for:

- BGP Neighbors
- BGP Session state
- Number of BGP Updates and Prefixes sent/received for each BGP Neighbor
- Keepalive counters


[JSON](./boards/grafana_fabric.json)

## Interfaces

![Example](./boards/Interfaces-stats.png) 


Switch interfaces monitoring visualization that includes:

- Interface Oper/Admin state
- Total input/output packets counter
- Input/output PPS/Bits rate
- Interface utilization
- Counters for Unicast/Broadcast/Multicast packets
- Errors and discards counters


[JSON](./boards/grafana_interfaces.json)

## Logs

System and fabric logs:

- Kernel and BGP logs from Syslog
- Errors in agent and syslog
- Full output of defined file

[JSON](./boards/grafana_logs.json)


## Platform

![Example](./boards/Platform-stats.png) 


Information from PSU, temperature sensors and fan trays:

- Input/output PSU voltage
- Fan speed
- Temperature from switch sensors (CPU, PSU, etc)
- For transceivers with DOM - optic sensor temperature


[JSON](./boards/grafana_platform.json)


## Node Exporter

![Example](./boards/NodeFull.png) 

[Grafana Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/) is an opensource Grafana board that provide
visualizations for monitoring Linux nodes. In particular case Node Exporter is used to track SONiC OS own stats such as

- Memory/disks usage
- CPU/System utilization
- Networking stats (traffic that hits SONiC interfaces)
...


[JSON](./boards/grafana_node_exporter.json)

