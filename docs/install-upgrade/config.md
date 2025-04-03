# Fabric Configuration
## Overview
The `fab.yaml` file is the configuration file for the fabric. It supplies
the configuration of the users, their credentials, logging, telemetry, and 
other non wiring related settings. The `fab.yaml` file is composed of multiple 
YAML documents inside of a single file. Per the YAML spec 3 hyphens (`---`) on 
a single line separate the end of one object from the beginning of the next. 
There are two YAML objects in the `fab.yaml` file. For more information about 
how to use `hhfab init`, run `hhfab init --help`.

## HHFAB workflow

After `hhfab` has been [downloaded](../getting-started/download.md):

1. `hhfab init`(see different flags to customize initial configuration)
1. Adjust the `fab.yaml` file to your needs
1. `hhfab validate`
1. `hhfab build`

Or import existing `fab.yaml` and wiring files:

1. `hhfab init -c fab.yaml -w wiring-file.yaml -w extra-wiring-file.yaml`
1. `hhfab validate`
1. `hhfab build`

After the above workflow a user will have a .img file suitable for installing the control node, then bringing up the switches which comprise the fabric.

## Complete Example File

``` { .yaml .annotate title="fab.yaml" linenums="1"} 
apiVersion: fabricator.githedgehog.com/v1beta1
kind: Fabricator
metadata:
  name: default
  namespace: fab
spec:
  config:
    control:
      tlsSAN: # IPs and DNS names to access API
        - "customer.site.io"

      ntpServers:
      - time.cloudflare.com
      - time1.google.com

      defaultUser: # username 'core' on all control nodes
        password: "hash..." # generate hash with openssl passwd -5
        authorizedKeys:
          - "ssh-ed25519 key..." # generate ssh key with ssh-keygen

    fabric:
      mode: spine-leaf # "spine-leaf" or "collapsed-core"
      includeONIE: true
      defaultSwitchUsers:
        admin: # at least one user with name 'admin' and role 'admin'
          role: admin
          password: "hash..." # generate hash with openssl passwd -5
          authorizedKeys:
            - "ssh-ed25519 key..."
        op: # optional read-only user
          role: operator
          password: "hash..." # generate hash with openssl passwd -5
          authorizedKeys:
            - "ssh-ed25519 key..." # generate ssh key with ssh-keygen

      defaultAlloyConfig:
        agentScrapeIntervalSeconds: 120
        unixScrapeIntervalSeconds: 120
        unixExporterEnabled: true
        collectSyslogEnabled: true
        lokiTargets:
          lab:
            url: http://url.io:3100/loki/api/v1/push
            labels:
              descriptive: name
        prometheusTargets:
          lab:
            url: http://url.io:9100/api/v1/push
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
    interface: eno2 # customer interface to manage control node
    ip: dhcp # IP address for external interface
  management: # interface that manages switches in private management network
    interface: eno1

# Currently only one ControlNode is supported
```

### Configure Control Node and Switch Users

#### Control Node Users
Configuring control node and switch users is done either passing 
`--default-password-hash` to `hhfab init` or editing the resulting `fab.yaml` 
file emitted by `hhfab init`.  The default username on the control node is
`core`.

#### Switch Users
There are two users on the switches, `admin` and `operator`. The `operator` user has
read-only access to `sonic-cli` command on the switches. The `admin` user has
broad administrative power on the switch. 
In order to avoid conflicts, do not use the following usernames: `operator`,`hhagent`,`netops`.

### NTP and DHCP
The control node uses public NTP servers from Cloudflare and Google by default.
The control node runs a DHCP server on the management network. See the [example
file](#complete-example-file).

### Control Node
The control node is the host that manages all the switches, runs k3s, and serves images. 
The **management** interface is for the control node to manage the fabric 
switches, *not* end-user management of the control node. For end-user 
management of the control node specify the **external** interface name.

### Telemetry

There is an option to enable [Grafana
Alloy](https://grafana.com/docs/alloy/latest/) on all switches to forward metrics and logs to the configured targets using
[Prometheus Remote-Write
API](https://prometheus.io/docs/specs/prw/remote_write_spec/) and Loki API. Metrics includes port speeds, counters, 
errors, operational status, transceivers, fans, power supplies, temperature
sensors, BGP neighbors, LLDP neighbors, and more. Logs include Hedgehog agent logs.

Telemetry can be enabled after installation of the fabric. Open the following
YAML file in an editor on the control node. Modify the fields as needed. Logs
can be pushed to a Grafana instance at the customer environment, or to Grafana
cloud.

```{ .yaml title="telemetry.yaml" linenums="1" }
spec:
  config:
    fabric:
      defaultAlloyConfig:
        agentScrapeIntervalSeconds: 120
        unixScrapeIntervalSeconds: 120
        unixExporterEnabled: true
        lokiTargets:
          grafana_cloud: # target name, multiple targets can be configured
              basicAuth: # optional
                  password: "<password>"
                  username: "<username>"
              labels: # labels to be added to all logs
                  env: env-1
              url: https://logs-prod-021.grafana.net/loki/api/v1/push
        prometheusTargets:
          grafana_cloud: # target name, multiple targets can be configured
              basicAuth: # optional
                  password: "<password>"
                  username: "<username>"
              labels: # labels to be added to all metrics
                  env: env-1
              sendIntervalSeconds: 120
              url: https://prometheus-prod-36-prod-us-west-0.grafana.net/api/prom/push
        unixExporterCollectors: # list of node-exporter collectors to enable, https://grafana.com/docs/alloy/latest/reference/components/prometheus.exporter.unix/#collectors-list
        - cpu
        - filesystem
        - loadavg
        - meminfo
        collectSyslogEnabled: true # collect /var/log/syslog on switches and forward to the lokiTargets
```

To enable the telemetry after install use:

``` shell
kubectl patch -n fab --type merge fabricator/default --patch-file telemetry.yaml
```

For additional options, see the `AlloyConfig` [struct in Fabric repo](https://github.com/githedgehog/fabric/blob/master/api/meta/alloy.go).

