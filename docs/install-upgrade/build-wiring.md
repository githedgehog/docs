# Build Wiring Diagram

!!! warning ""
    Under construction.

You can find more details in the User Guide including [switch features and port naming](../user-guide/profiles.md). It's mandatoy to for all switches to reference a `SwitchProfile` in the `spec.profile` of the `Switch` object. Only port naming defined by switch profiles could be used in the wiring diagram, NOS (or any other) port names aren't supported.

In the meantime, to have a look at working wiring diagram for Hedgehog Fabric, run the sample generator that produces
VLAB-compatible wiring diagrams:

```console
ubuntu@sl-dev:~$ hhfab sample -h

NAME:
   hhfab sample - generate sample wiring diagram

USAGE:
   hhfab sample command [command options]

COMMANDS:
   spine-leaf, sl      generate sample spine-leaf wiring diagram
   collapsed-core, cc  generate sample collapsed-core wiring diagram
   help, h             Shows a list of commands or help for one command

OPTIONS:
   --help, -h  show help
```

