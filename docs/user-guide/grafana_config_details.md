# Telemetry Configuration

## Credentials

Apply the setting to your fabric that will allow for telemetry to be pushed to
the specified Grafana instance:

```
spec:
  config:
    observability:
      targets:
        loki:
          grafana_cloud:
            basicAuth:
              password: token_with_log_write_permission
              username: "1234567"
            labels:
              env: production
            url: https://logs-prod-021.grafana.net/loki/api/v1/push
        prometheus:
          grafana_cloud:
            basicAuth:
              password: token_with_metric_write_permission
              username: "1234567"
            labels:
              env: production
            url: https://prometheus-prod-36-prod-us-west-0.grafana.net/api/prom/push

```

### Tokens

Grafana Cloud manages read and write permissions with policies. In order to
send metrics to the datasources a policy for your realm needs to be created.
When creating the policy ensure that it has at least `logs:write` and `metrics:write` permission
selected. After the policy is created, add a token to that policy ensure that
it is appropriately named and time limited. Once the token is created use it in
the credentials YAML file. For additional details see the
[documentation](https://grafana.com/docs/grafana-cloud/security-and-account-management/authentication-and-permissions/access-policies/)


## Configuration
The second yaml section controls what is pushed from the fabric to prometheus

```
spec:
  config:
    fabric:
      observability:
        agent: 
          logs: true
          metrics: true
          metricsInterval: 60
          metricsRelabel: 
          - action: keep
            regex: .*(_resource_|_interface_|_platform_|_bgp_|node_|_heartbeats_|_generation|_status).*
            sourceLabels:
            - __name__
        unix: 
          metrics: true
          metricsCollectors:
          - cpu
          - loadavg
          - meminfo
          - filesystem
          metricsInterval: 60
          metricsRelabel: 
          - action: keep
            regex: .*(_load).*
            sourceLabels:
            - __name__
          syslog: true
```


## Alerting

![Screenshot of grafana alerting page](./boards/Alert-Rule.png)

The alert rule queries the increase of the
`fabric_agent_agent_heartbeats_total` metric. In normal operation the switch agent sends two
increments every minute. The [prometheus
`increase`](https://prometheus.io/docs/prometheus/latest/querying/functions/#increase) function will extrapolate
the value for the total time range which leads to a higher reported number
than is actually observed, this is not a concern. Select a value for the Alert
condition according to your operational needs. The example has a value of 3,
which allows for some delays and drops before firing the alarm.

For convenience [here is the JSON](./boards/grafana_alarm.json) used to
configure this alarm. Values that should be changed to match your environment
contain the string "Hedgehog".

Grafana has a [learning
journey](https://grafana.com/docs/learning-journeys/logs-alert-creation/) to
assist users in creating and configuring alerts.
