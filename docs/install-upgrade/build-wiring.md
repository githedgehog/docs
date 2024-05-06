# Build Wiring Diagram

!!! warning ""
    Under construction.

In the meantime, to have a look at working wiring diagram for Hedgehog Fabric, run the sample generator that produces
VLAB-compatible wiring diagrams:

```console
ubuntu@sl-dev:~$ hhfab wiring sample -h
NAME:
   hhfab wiring sample - sample wiring diagram (would work for vlab)

USAGE:
   hhfab wiring sample [command options] [arguments...]

OPTIONS:
   --brief, -b                    brief output (only warn and error) (default: false)
   --fabric-mode value, -m value  fabric mode (one of: collapsed-core, spine-leaf) (default: "spine-leaf")
   --help, -h                     show help
   --verbose, -v                  verbose output (includes debug) (default: false)

   wiring generator options:

   --chain-control-link         chain control links instead of all switches directly connected to control node if fabric mode is spine-leaf (default: false)
   --control-links-count value  number of control links if chain-control-link is enabled (default: 0)
   --fabric-links-count value   number of fabric links if fabric mode is spine-leaf (default: 0)
   --mclag-leafs-count value    number of mclag leafs (should be even) (default: 0)
   --mclag-peer-links value     number of mclag peer links for each mclag leaf (default: 0)
   --mclag-session-links value  number of mclag session links for each mclag leaf (default: 0)
   --orphan-leafs-count value   number of orphan leafs (default: 0)
   --spines-count value         number of spines if fabric mode is spine-leaf (default: 0)
   --vpc-loopbacks value        number of vpc loopbacks for each switch (default: 0)
```
