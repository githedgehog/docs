# Fabric Configuration
## Overview
The `fab.yaml` file is the configuration file for the fabric. It supplies
the configuration of the users, their credentials, logging, telemetry, and
other non wiring related settings. The `fab.yaml` file is composed of multiple
YAML objects inside of a single file. Per the YAML spec 3 hyphens (`---`) on
a single line separate the end of one object from the beginning of the next.
There are two YAML objects in the `fab.yaml` file. For more information about
how to use `hhfab init`, run `hhfab init --help`.

## HHFAB workflow

After `hhfab` has been [downloaded](../getting-started/download.md):

1. `hhfab init`(see different flags to customize initial configuration)
1. Adjust the `fab.yaml` file to your needs
1. Build your [wiring diagram](build-wiring.md)
1. `hhfab validate`
1. (optionally) `hhfab diagram`
1. `hhfab build`

Or import existing `fab.yaml` and wiring files:

1. `hhfab init -c fab.yaml -w wiring-file.yaml -w extra-wiring-file.yaml`
1. `hhfab validate`
1. Build your [wiring diagram](build-wiring.md)
1. (optionally) `hhfab diagram`
1. `hhfab build`

After the above workflow a user will have a .img file suitable for installing the control node, then bringing up the switches which comprise the fabric.

## Complete Example File

The following example outlines a comprehensive Fabricator configuration. You
can find further configuration details in the Fabricator [API
Reference](../reference/fab-api.md).

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
      mode: spine-leaf # only mode supported, kept for compatibility
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
---
apiVersion: fabricator.githedgehog.com/v1beta1
kind: FabNode
metadata:
  name: gateway-1
  namespace: fab
spec:
  roles:
    - gateway
  bootstrap:
   disk: "/dev/sda" # disk to install OS on, e.g. "sda" or "nvme0n1"
  management: # interface that connects gateway to private hh managment network
    interface: enp2s0
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
To avoid conflicts, do not use the following usernames: `operator`,`hhagent`,`netops`.

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
sensors, BGP neighbors, LLDP neighbors, and more. Logs include Hedgehog agent
logs. Modify the URL as needed, instead of `/api/v1/push` it could be
`/api/v1/write`; check the documentation for the data provider.

Switches push telemetry data through a proxy running in a pod on the control
node. Switches do not have direct access to the Internet. Configure the control node to be able to reach and resolve the location
of the Prometheus and Loki servers.

Telemetry can be enabled after installation of the fabric. There are two YAML
objects that control the telemetry configuration. The first YAML object
configures the credentials and  URL for the collectors. The second configures
which metrics are sent via Grafana Alloy.

#### Credentials

The first object provides the URL and credentials for sending the telemetry.
This can be obtained from the Grafana cloud dashboard by selecting details on
the desired stack, then details again on the collector, Prometheus. Be sure to 
choose the URL for "Remote Write". Use the YAML listing below as a template and
fill in your, username, token/password, and URL.

```{ .yaml .annotate title="credentials.yaml" linenums="1" }
spec:
  config:
    observability:
      targets:
        loki:
          grafana_cloud: # (1)!
            basicAuth:
              password: "insert_password_or_token_here"
              username: "username"
            labels: 
              env: hh-fabric # (2)!
            url: https://[your-loki-server].grafana.net/loki/api/v1/push
        prometheus:
          grafana_cloud: # (3)!
            basicAuth:
              password: "insert_password_or_token_here"
              username: "username"
            labels:
              env: hh-fabric
            url: https://[your-prometheus-server].grafana.net/api/prom/push

```

1. Can be any name of your choosing
2. Change to match your environment
3. Can be any name of your choosing

To apply these changes to the fabric use:

``` shell
kubectl patch -n fab --type merge fabricator/default --patch-file credentials.yaml
```


#### Collecting and Pushing

The second YAML object controls which metrics are sent from the fabric to
the collectors. By default the full list of telemetry is sent from the fabric to Prometheus and 
Loki. In the example the metrics are restricted to those matching the regular
expression, everything else is discarded. 

```{ .yaml .annotate title="config.yaml" linenums="1" }
spec:
  config:
    fabric:
      observability:
        agent: # (1)!
          logs: true
          metrics: true
          metricsInterval: 60
          metricsRelabel: # (2)!
          - action: keep
            regex: .*(_in_bits|_status|_generation|_temperature|_transceiver).*
            sourceLabels:
            - __name__
        unix: # (3)!
          metrics: true
          metricsCollectors:
          - cpu
          - loadavg
          - meminfo
          - filesystem
          metricsInterval: 60
          metricsRelabel: # (4)!
          - action: keep
            regex: .*(_load).*
            sourceLabels:
            - __name__
          syslog: true
```

1. The Hedgehog agent generates information from the ASIC ports and switch
   configuration
2. This option mirrors the [prometheus.relabel](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel) component
3. Alloy is configured to use the [prometheus.exporter.unix](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.unix/) component
4. This option mirrors the [prometheus.relabel](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/) component

Users are encouraged to read the [Grafana Alloy
Docs](https://grafana.com/docs/grafana-cloud/send-data/alloy/tutorials/logs-and-relabeling-basics/)
on relabeling to ensure the desired metrics are selected. By default all
metrics are sent to the collectors.

As above, to apply these changes to the fabric use the following command:

``` shell
kubectl patch -n fab --type merge fabricator/default --patch-file config.yaml
```

