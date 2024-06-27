# Fabric Configuration

* `--fabric-mode <mode-name` (`collapsed-core` or `spine-leaf`) - Fabric mode to use, default is `spine-leaf`; in case
    of `collapsed-core` mode, there will be no VXLAN configured and only 2 switches will be used
* `--ntp-servers <servers>`- Comma-separated list of NTP servers to use, default is
    `time.cloudflare.com,time1.google.com,time2.google.com,time3.google.com,time4.google.com`, it'll be used for both
    control nodes and switches
* `--dhcpd <mode-name>` (`isc` or `hedgehog`) - DHCP server to use, default is `isc`; `hedgehog` DHCP server enables
    use of on-demand DHCP for multiple IPv4/VLAN namespaces and overlapping IP ranges, and it adds DHCP leases
    into the Fabric API

For more information about how to use `hhfab init`, run `hhfab init --help`.

## Configure switch users

It's currently only possible by using a config yaml file for the `hhfab init -c <config-file.yaml>` command. You can
specify users to be configured on the switches in the following format:

```yaml
config:
    ...
    fabric:
        ...
        switchUsers:
          - name: test
            password: $5$oj/NxDtFw3eTyini$VHwdjWXSNYRxlFMu.1S5ZlGJbUF/CGmCAZIBroJlax4
            role: operator
```

Where `name` is the username, `password` is the password hash created with `openssl passwd -5` command, and `role` is
the role of the user, one of `admin` or `operator` (read-only access to `sonic-cli` command on the switches).

## Forward switch metrics and logs

There is an option to enable Grafana Alloy on all switches to forward metrics and logs to the configured targets using
Prometheus Remote-Write API and Loki API. If those APIs are available from Control Node(s), but not from the switches,
it's possible to enable HTTP Proxy on Control Node(s) that will be used by Grafana Alloy running on the switches to
access the configured targets. It could be done by passing `--control-proxy=true` to `hhfab init`.

Metrics includes port speeds, counters, errors, operational status, transceivers, fans, power supplies, temperature
sensors, BGP neighbors, LLDP neighbors, and more. Logs include agent logs.

Configuring the exporters and targets is currently only possible by using a config yaml file for the
`hhfab init -c <config-file.yaml>` command using the following format:

```yaml
config:
    ...
    fabric:
        ...
        controlProxy: true # (optional) same as passing --control-proxy=true to hhfab init
        alloy:
            agentScrapeIntervalSeconds: 120
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
            unixExporterEnabled: true
            unixScrapeIntervalSeconds: 120
            collectSyslogEnabled: true # collect /var/log/syslog on switches and forward to the lokiTargets
```

For additional options, see the `AlloyConfig` [struct in Fabric repo](https://github.com/githedgehog/fabric/blob/master/api/meta/alloy.go).
