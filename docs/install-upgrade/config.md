# Fabric Configuration
## Overview
The `fab.yaml` file is the configuration file for the fabric. It supplies the configuration of the users, their credentials, logging, telemetry, and other non wiring related settings. The `fab.yaml` file is composed of multiple yaml documents inside of a single file. Per the yamls spec 3 hyphens (`---`) on a single line separate the end of one document from the beginning of the next. There are two yaml documents in the `fab.yaml` file. For more information about how to use `hhfab init`, run `hhfab init --help`. 

## Fabric 

The fabric yaml object has 4 objects:

- `mode` - either `spine-leaf` or `collapsed-core`
- `includeONIE` - defaults to true
- `defaultSwitchUsers` - the admin and operator credentials for SONiC.
- `defaultAlloyConfig` - The configuration details for telemetry of switch information

### Forward switch metrics and logs

There is an option to enable Grafana Alloy on all switches to forward metrics and logs to the configured targets using
Prometheus Remote-Write API and Loki API. If those APIs are available from Control Node(s), but not from the switches,
it's possible to enable HTTP Proxy on Control Node(s) that will be used by Grafana Alloy running on the switches to
access the configured targets. It could be done by passing `--control-proxy=true` to `hhfab init`.

Metrics includes port speeds, counters, errors, operational status, transceivers, fans, power supplies, temperature
sensors, BGP neighbors, LLDP neighbors, and more. Logs include agent logs.

Configuring the exporters and targets is currently only possible by using a yaml configuration file for the
`hhfab init -c <config-file.yaml>` command using the following format:

```yaml
spec:
  config:
      ...
      defaultAlloyConfig:
        agentScrapeIntervalSeconds: 120
        unixScrapeIntervalSeconds: 120
        unixExporterEnabled: true
        controlProxy: true # (optional) same as passing --control-proxy=true to hhfab init
        controlProxyURL: http://172.30.1.1:31028
        lokiTargets:
          grafana_cloud: # target name, multiple targets can be configured
              basicAuth: # optional
                  password: "<password>"
                  username: "<username>"
              labels: # labels to be added to all logs
                  env: env-1
              url: https://logs-prod-021.grafana.net/loki/api/v1/push
              useControlProxy: true # if the Loki API is not available from the switches directly, use the Control Node as a proxy
        prometheusTargets:
          grafana_cloud: # target name, multiple targets can be configured
              basicAuth: # optional
                  password: "<password>"
                  username: "<username>"
              labels: # labels to be added to all metrics
                  env: env-1
              sendIntervalSeconds: 120
              url: https://prometheus-prod-36-prod-us-west-0.grafana.net/api/prom/push
              useControlProxy: true # if the Loki API is not available from the switches directly, use the Control Node as a proxy
              unixExporterCollectors: # list of node-exporter collectors to enable, https://grafana.com/docs/alloy/latest/reference/components/prometheus.exporter.unix/#collectors-list
                  - cpu
                  - filesystem
                  - loadavg
                  - meminfo
              collectSyslogEnabled: true # collect /var/log/syslog on switches and forward to the lokiTargets
```

For additional options, see the `AlloyConfig` [struct in Fabric repo](https://github.com/githedgehog/fabric/blob/master/api/meta/alloy.go).

### Configure switch users

It's currently only possible by using a yaml configuration file for the `hhfab init -c <config-file.yaml>` command. You can specify users to be configured on the switches in the following format:
```yaml
spec:
    config:
      control:
        defaultUser: # user 'core' on all control nodes
          password: "hashhashhashhashhash" # password hash
          authorizedKeys:
            - "ssh-ed25519 SecREKeyJumblE"

        fabric:
          mode: spine-leaf # "spine-leaf" or "collapsed-core"
          
          defaultSwitchUsers: 
            admin: # at least one user with name 'admin' and role 'admin'
              role: admin
              #password: "$5$8nAYPGcl4..." # password hash
              #authorizedKeys: # optional SSH authorized keys
              #  - "ssh-ed25519 AAAAC3Nza..."
            op: # optional read-only user
              role: operator
              #password: "$5$8nAYPGcl4..." # password hash
              #authorizedKeys: # optional SSH authorized keys
              #  - "ssh-ed25519 AAAAC3Nza..."

```
The role of the user,`operator` is read-only access to `sonic-cli` command on the switches. In order to avoid conflicts, do not use the following usernames: `operator`,`hhagent`,`netops`.

## Control Node
This is the yaml document configure the control node:
```yaml
apiVersion: fabricator.githedgehog.com/v1beta1
kind: ControlNode
metadata:
  name: control-1
  namespace: fab
spec:
  bootstrap:
   disk: "/dev/sda" # disk to install OS on, e.g. "sda" or "nvme0n1"
  external:
    interface: enp2s0 # interface for external
    ip:	dhcp # IP address for external interface
  management:
    interface: enp2s1 # interface for management

# Currently only one ControlNode is supported
```
The **management** interface is for the control node to manage the fabric switches, *not* end-user management of the control node. For end user management of the control node specify the **external** interface name.

## Complete Example File
```yaml
apiVersion: fabricator.githedgehog.com/v1beta1
kind: Fabricator
metadata:
  name: default
  namespace: fab
spec:
  config:
    control:
      tlsSAN: # IPs and DNS names that will be used to access API
        - "env-2.l.hhdev.io"

      defaultUser: # user 'core' on all control nodes
        password: "hash..." # password hash
        authorizedKeys:
          - "ssh-ed25519 hash..."

    fabric:
      mode: spine-leaf # "spine-leaf" or "collapsed-core"
      includeONIE: true
      defaultSwitchUsers:
        admin: # at least one user with name 'admin' and role 'admin'
          role: admin
          password: "hash..." # password hash
          authorizedKeys:
            - "ssh-ed25519 hash..."
        op: # optional read-only user
          role: operator
          password: "hash..." # password hash
          authorizedKeys:
            - "ssh-ed25519 hash..."

      defaultAlloyConfig:
        agentScrapeIntervalSeconds: 120
        unixScrapeIntervalSeconds: 120
        unixExporterEnabled: true
        collectSyslogEnabled: true
        lokiTargets:
          lab:
            url: http://url.io:3100/loki/api/v1/push
            useControlProxy: true
            labels:
              descriptive: name
        prometheusTargets:
          lab:
            url: http://url.io:9100/api/v1/push
            useControlProxy: true
            labels:
              descriptive: name
            sendIntervalSeconds: 120

---
apiVersion: fabricator.githedgehog.com/v1beta1
kind: ControlNode
metadata:
  name: control-1
  namespace: fab
spec:
  bootstrap:
    disk: "/dev/sda" # disk to install OS on, e.g. "sda" or "nvme0n1"
  external:
    interface: eno2 # interface for external
    ip: dhcp # IP address for external interface
  management:
    interface: eno1

# Currently only one ControlNode is supported
```
