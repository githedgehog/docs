# The Switch Agent

## Agent Overview

The agent is a process authored by Hedgehog that creates and enforce the
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

## Heart Beats

### Diagnosing Long or Missing Heart beats

If the duration between heart beats is greater than 1 minute, one of several
things could be happening:

* The connection between the switch and the control node is down or misconfigured.
* The agent isn't running on the switches
* The agent is stuck trying to apply a configuration

#### Switch and Controller Connection

The controller serves DHCP to the switches as part of normal operation and
replies to ONIE requests for NOS install. The controller expects layer 2
reachability and to be the only DHCP sever in the LAN. This architecture
can take many forms but it is most often a dedicated switch or private VLAN.
Ensure that the link on the controller is in the `up` state. Often problems
in this area are related to the configuration of a private VLAN, or cabling.

#### Starting and Stopping the Agent

The switch agent is a daemon that is controlled via `systemctl` commands.
The agent is started automatically at switch bootup time, to stop the agent:
```bash
sudo systemctl stop hedgehog-agent.service
```
similarly to start the agent:
```bash
sudo systemctl start hedgehog-agent.service
```

Stopping the agent should only be done as part of a debugging, as the agent will
reapply the configuration on a regular interval.

#### Restoring Agent State

If an agent is stuck trying to apply a configuration, the configuration can be
generated on the control node using `kubectl`, then manually moved to the
switch. The example below uses the name of a switch for illustrative purposes.

1. on control node: `kubectl get -o yaml agents/switch-name > agent-config.yaml`
1. on control node: `scp agent-config.yaml admin@leaf-04:/tmp/agent-config.yaml`
1. on control node: `ssh admin@leaf-04`
1. on switch: `sudo mv /tmp/agent-config.yaml /etc/sonic/hedgehog/agent-config.yaml`


## Applied, AppliedG, and CurrentG

Each configuration on the switches is tracked as a generation. The `APPLIEDG`
column indicates the generation that is the running configuration on the switch.
After a change is made, the `CURRENTG` column will be higher than the `APPLIEDG`
The switch agent will apply the changes and the `CURRENTG` column will equal
the `APPLIEDG` column. The `APPLIED` column displays the amount of time that
has passed since the last configuration was applied.

## ROCE, ECMPQPN

The `ROCE` column indicates if the switch is in RoCE mode. To change into RoCE
mode the switch requires a reboot. The `CURROCE` column will indicate `true` if the
switch is rebooting as part of the RoCE enablement.
