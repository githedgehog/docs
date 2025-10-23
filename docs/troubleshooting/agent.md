# The Switch Agent

## Agent Overview

The agent is a process authored by Hedgehog that creates and enforces the
switch configurations. To view the status of every switch agent:

```console
core@control-1 ~ $ kubectl get -o wide agents
NAME           ROLE          DESCR         HWSKU                      ASIC       HEARTBEAT   APPLIED   APPLIEDG   CURRENTG   VERSION   SOFTWARE                ATTEMPT   ATTEMPTG   ROCE   CURRROCE   ECMPQPN   AGE
as4630-01      server-leaf   leaf-4        Accton-AS4630-54NPE        broadcom   21s         31m       35         35         v0.84.3   4.5.0-Campus            31m       35                                     18d
as7326-01      server-leaf   leaf-2        Accton-AS7326-56X          broadcom   15s         7m12s     46         46         v0.84.3   4.5.0-Enterprise_Base   7m12s     46         true   true                 18d
as7712-01      spine         spine-1       Accton-AS7712-32X          broadcom   28s         37m       7          7          v0.84.3   4.5.0-Enterprise_Base   37m       7                                      18d
as7712-02      spine         spine-2       Accton-AS7712-32X          broadcom   22s         17m       6          6          v0.84.3   4.5.0-Enterprise_Base   17m       6                                      18d
s5248-05       server-leaf   leaf-1        DellEMC-S5248f-P-25G-DPB   broadcom   16s         85s       38         38         v0.84.3   4.5.0-Enterprise_Base   85s       38         true   true                 18d
ds3000-01      server-leaf   leaf-5        DS3000                     broadcom   10s         23m       37         37         v0.84.3   4.5.0-Enterprise_Base   23m       37                                     18d
```

## Heartbeats

Heartbeats are messages between the control node and the switches. The purpose
of sending these messages is to confirm that the switches are reachable and
responding to the commands of the control node. To check the status of the agent:

```bash
systemctl status hedgehog-agent.service
```

### Diagnosing Long or Missing Heartbeats

If the duration between heart beats is greater than 1 minute, one of several
things could be happening:

* The connection between the switch and the control node is down or misconfigured.
* The agent isn't running on the switches
* The agent is stuck trying to apply a configuration
* The time is not synchronized between the control node and the switches

#### Switch and Control Node Connection

The control node serves DHCP to the switches as part of normal operation and
replies to ONIE requests for NOS install. The control node expects layer 2
reachability and to be the only DHCP server in the LAN. This architecture
can take many forms but it is most often a dedicated switch or VLAN.
Ensure that the link on the control node is in the `up` state. Often problems
in this area are related to the configuration of a private VLAN, or cabling.

#### Starting and Stopping the Agent

The switch agent is a service that is controlled via `systemctl` commands.
The agent is started automatically at switch bootup time, to stop the agent:
```bash
sudo systemctl stop hedgehog-agent.service
```
similarly to start the agent:
```bash
sudo systemctl start hedgehog-agent.service
```

Stopping the agent should only be done as part of debugging, because the agent will
reapply the configuration on a regular interval during normal operation.

#### Restoring Agent State

In some cases, the Switch Agent may become unable to apply  configuration
changes. If the agent continues to log the same configuration diff for longer
than five minutes, it can be considered stuck. Before attempting these steps 
reach out to Hedgehog as this is likely a bug. If an agent is stuck, the 
configuration can be generated on the control node using `kubectl`, then manually 
moved to the switch. The example below uses the name of a switch for illustrative purposes.

1. on control node: `kubectl get -o yaml agents/switch-name > agent-config.yaml`
1. on control node: `scp agent-config.yaml admin@leaf-04:/tmp/agent-config.yaml`
1. on control node: `ssh admin@leaf-04`
1. on switch: `sudo systemctl stop hedgehog-agent.service`
1. on switch: `sudo mv /tmp/agent-config.yaml /etc/sonic/hedgehog/agent-config.yaml`
1. on switch: `sudo systemctl start hedgehog-agent.service`

If the agent doesn't return to normal functioning after this procedure the next
step would be to schedule downtime and reboot the switch.

#### Time Synchronization

The control node is configured to use public NTP servers from Google or
Cloudflare. The control node will also act as an NTP server for the switches.

To check the sync status of the control node, use the `timedatectl`
command:

```bash
timedatectl timesync-status
```

If the time is not correct, view the logs of the NTP pod with:

```bash
kubectl -n fab logs deployment/ntp
```

Confirm that the switches are using the control node as their NTP source:

```console
admin@leaf-01:~$ show ntp 
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*172.30.0.1      216.239.35.0     2 u  339 1024  377    1.365   +0.276   0.300
synchronised to NTP server (172.30.0.1) at stratum 3 
   time correct to within 31 ms
   polling server every 1024 s
```

The `*` character next to the remote IP address indicates the switch is
using the chrony pod as its NTP server. The Hedgehog agent sets the NTP
configuration on the switch.

## Applied, AppliedG, and CurrentG

Each configuration on the switches is tracked as a generation. The `APPLIEDG`
column indicates the generation that is the running configuration on the switch.
After a change is made, the `CURRENTG` column will be higher than the `APPLIEDG`
The switch agent will apply the changes and the `CURRENTG` column will equal
the `APPLIEDG` column. The `APPLIED` column displays the amount of time that
has passed since the last configuration was applied.

## RoCE, ECMPQPN

The `RoCE` column indicates if the user has declared that the switch should be
in RoCE mode. To change into RoCE mode the switch requires a reboot. The 
`CURROCE` column indicates `true` if the
switch is in RoCE mode. The `ECMPQPN` column indicates if the user has declared
that the switch should have configured ECMP QPN.
