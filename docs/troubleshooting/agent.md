# The Switch Agent

## Background

The agent is a process authored by Hedgehog to create and enforce the
configurations that are created by the user on the control node.


## Missing or Slow Heartbeats

### Checking Heartbeats

Heartbeats can be viewed via the `agents` section of `k9s`. They can also be
viewed via kubectl:
```console
kubectl get -o wide agent
core@control-1 ~ $ kubectl get -o wide agents
NAME           ROLE          DESCR         HWSKU                      ASIC       HEARTBEAT   APPLIED   APPLIEDG   CURRENTG   VERSION   SOFTWARE                ATTEMPT   ATTEMPTG   ROCE   CURRROCE   ECMPQPN   AGE
as4630-01      server-leaf   leaf-4        Accton-AS4630-54NPE        broadcom   21s         31m       35         35         v0.84.3   4.5.0-Campus            31m       35                                     18d
as7326-01      server-leaf   leaf-2        Accton-AS7326-56X          broadcom   15s         7m12s     46         46         v0.84.3   4.5.0-Enterprise_Base   7m12s     46         true   true                 18d
as7712-01      spine         spine-1       Accton-AS7712-32X          broadcom   28s         37m       7          7          v0.84.3   4.5.0-Enterprise_Base   37m       7                                      18d
as7712-02      spine         spine-2       Accton-AS7712-32X          broadcom   22s         17m       6          6          v0.84.3   4.5.0-Enterprise_Base   17m       6                                      18d
s5248-05       server-leaf   leaf-1        DellEMC-S5248f-P-25G-DPB   broadcom   16s         85s       38         38         v0.84.3   4.5.0-Enterprise_Base   85s       38         true   true                 18d
ds3000-01      server-leaf   leaf-5        DS3000                     broadcom   10s         23m       37         37         v0.84.3   4.5.0-Enterprise_Base   23m       37                                     18d
```

The heartbeat is expected to be below `1m` before resetting.

#### Diagnosing Long or Missing Heartbeats


