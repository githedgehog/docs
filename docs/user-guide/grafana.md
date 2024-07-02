# Grafana Dashboards

To provide monitoring for most critical metrics from the switches managed by Hedgehog Fabric there are several Dashboards that may be used in Grafana deployments.

## Alloy enablement

`hedgehog-alloy` is installed for each SONiC-based switch in Hedgehog Fabric. However, the configuration of service has to be defined on the Fabric init stage.
Following config should be added to `hhfab.yaml` init file.

```yaml
...
  fabric:
    controlProxy: true
    alloy:
      agentScrapeIntervalSeconds: # Interval between metrics collection from agent
      unixScrapeIntervalSeconds: # Interval between metrics collection for Node Exporter
      unixExporterEnabled: true # Enble Node Exporter Full
      collectSyslogEnabled: true # Enable inspection of Syslog in Loki
      lokiTargets:
        lab:
          url: # Url for Loki to push logs
          useControlProxy: true # Route messages through Control node
          labels:
            env: # Environment name applied as label on metrics
      prometheusTargets:
        lab:
          url: # Url for Prometheus to push metrics
          useControlProxy: true
          labels:
            env: 
          sendIntervalSeconds: # Interval between pushes to Prometheus collector
          ...
```


## Variables
List of common variables used in Hedgehog Grafana dashboards

- **env** (Label: Env): `label_values(env)` - Environment to monitor
- **node** (Label: Switch): `label_values(hostname)` - Switch Name
- **vrf** (Label: VRF): `label_values(vrf)` - VRF name (Multi-value)
- **neighbor** (Label: Neighbor): `label_values(neighbor)` - BGP Neighbor IP address(Multi-value)
- **interface** (Label: Interface): `label_values(interface)` - Switch Interface name as defined in wiring (Multi-value)
- **file** (Label: File): `label_valuse(filename)` - Name of Logs file to inspect (Loki)

## Switch Critical Resources

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

Fabric underlay and external peering monitoring. Including reporing for:

- BGP Neighbors
- BGP Session state
- Number of BGP Updates and Prefixes sent/received for each BGP Neighbor
- Keepalive counters


[JSON](./boards/grafana_fabric.json)

## Interfaces

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

Information from PSU, temperature sensors and fan trays:

- Input/output PSU voltage
- Fan speed
- Temperature from switch sensors (CPU, PSU, etc)
- For transceivers with DOM - optic sensor temperature


[JSON](./boards/grafana_platform.json)

## Node Exporter

[Grafana Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/) is an opensource Grafana board that provide
visualizations for monitoring Linux nodes. In particular case Node Exporter is used to track SONiC OS own stats such as

- Memory/disks usage
- CPU/System utilization
- Networking stats (traffic that hits SONiC interfaces)
...


[JSON](./boards/grafana_node_exporter.json)