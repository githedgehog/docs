<!--@@joggrdoc@@-->
<!-- @joggr:version(v1):end -->
<!-- @joggr:warning:start -->
<!-- 
  _   _   _    __        __     _      ____    _   _   ___   _   _    ____     _   _   _ 
 | | | | | |   \ \      / /    / \    |  _ \  | \ | | |_ _| | \ | |  / ___|   | | | | | |
 | | | | | |    \ \ /\ / /    / _ \   | |_) | |  \| |  | |  |  \| | | |  _    | | | | | |
 |_| |_| |_|     \ V  V /    / ___ \  |  _ <  | |\  |  | |  | |\  | | |_| |   |_| |_| |_|
 (_) (_) (_)      \_/\_/    /_/   \_\ |_| \_\ |_| \_| |___| |_| \_|  \____|   (_) (_) (_)
                                                              
This document is managed by Joggr. Editing this document could break Joggr's core features, i.e. our 
ability to auto-maintain this document. Please use the Joggr editor to edit this document 
(link at bottom of the page).
-->
<!-- @joggr:warning:end -->
# Build Wiring Diagram

!!! warning ""
    Under construction.

In the meantime, to have a look at the working wiring diagram for the Hedgehog Fabric, please run sample generator that
produces VLAB-compatible wiring diagrams:

```bash
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

<!-- @joggr:editLink(0a1bd8a4-08bf-4980-b8c1-d08989672749):start -->
---
<a href="https://app.joggr.io/app/documents/0a1bd8a4-08bf-4980-b8c1-d08989672749/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(0a1bd8a4-08bf-4980-b8c1-d08989672749):end -->