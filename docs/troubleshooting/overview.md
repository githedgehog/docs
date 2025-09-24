# Overview

## Inspecting the Fabric

The `kubectl` plugin, `fabric` has an `inspect` functionality that shows an
overview of the fabric. `kubectl fabric inspect` also shows detailed
information that is useful when diagnosing problems. To run the inspect
command:

```console
core@control-1 ~ $ kubectl fabric inspect fabric
Switches:
NAME        PROFILE           ROLE           GROUPS     SERIAL       STATE    GEN    APPLIED          HEARTBEAT
leaf-01     Virtual Switch    server-leaf    mclag-1    000000000    Ready    1/1    4 minutes ago    15 seconds ago
leaf-02     Virtual Switch    server-leaf    mclag-1    000000000    Ready    1/1    3 minutes ago    19 seconds ago
leaf-03     Virtual Switch    server-leaf    eslag-1    000000000    Ready    2/2    5 minutes ago    12 seconds ago
leaf-04     Virtual Switch    server-leaf    eslag-1    000000000    Ready    2/2    3 minutes ago    17 seconds ago
leaf-05     Virtual Switch    server-leaf               000000000    Ready    2/2    5 minutes ago    9 seconds ago
spine-01    Virtual Switch    spine                     000000000    Ready    1/1    3 minutes ago    19 seconds ago
spine-02    Virtual Switch    spine                     000000000    Ready    2/2    4 minutes ago    1 second ago
```

The output above is from the virtual testing environment. In a deployment of physical
switches, the profile would match the profile of the switch, and the correct
serial number would be displayed.

The `GROUP` column will be populated if you have redundancy configured on the
switches, either MCLAG, or ESLAG.

The `GEN` column shows the applied/current generation. If the numbers are equal
then there are no pending changes for the switches.

The `APPLIED` column shows the amount of time since the last change was applied.

The `HEARTBEAT` column show the amount of time since the controller received a
heartbeat from the switch. In normal operation value in this column will be less
than 60 seconds.
