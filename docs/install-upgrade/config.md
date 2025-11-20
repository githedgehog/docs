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
