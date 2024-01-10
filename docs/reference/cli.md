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
# Fabric CLI

!!! warning ""
    Under construction.

Currently Fabric CLI is represented by a kubectl plugin `kubectl-fabric` automatically installed on the Control Node.
It is a wrapper around `kubectl` and Kubernetes client which allows to manage Fabric resources in a more convenient way.
Fabric CLI only provides a subset of the functionality available via Fabric API and is focused on simplifying objects
creation and some manipulation with the already existing objects while main get/list/update operations are expected to
be done using `kubectl`.

```bash
core@control-1 ~ $ kubectl fabric
NAME:
   hhfctl - Hedgehog Fabric user client

USAGE:
   hhfctl [global options] command [command options] [arguments...]

VERSION:
   v0.23.0

COMMANDS:
   vpc                VPC commands
   switch, sw, agent  Switch/Agent commands
   connection, conn   Connection commands
   switchgroup, sg    SwitchGroup commands
   external           External commands
   help, h            Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --verbose, -v  verbose output (includes debug) (default: true)
   --help, -h     show help
   --version, -V  print the version
```

## VPC

Create VPC named `vpc-1` with subnet `10.0.1.0/24` and VLAN `1001` with DHCP enabled and DHCP range starting from
`10.0.1.10` (optional):

```bash
core@control-1 ~ $ kubectl fabric vpc create --name vpc-1 --subnet 10.0.1.0/24 --vlan 1001 --dhcp --dhcp-start 10.0.1.10
```

Attach previously created VPC to the server `server-01` (which is connected to the Fabric using the
`server-01--mclag--leaf-01--leaf-02` Connection):

```bash
core@control-1 ~ $ kubectl fabric vpc attach --vpc-subnet vpc-1/default --connection server-01--mclag--leaf-01--leaf-02
```

To peer VPC with another VPC (e.g. `vpc-2`) use the following command:

```bash
core@control-1 ~ $ kubectl fabric vpc peer --vpc vpc-1 --vpc vpc-2
```
<!-- @joggr:editLink(110fa0bb-3e32-430e-ad53-386f9f8886a9):start -->
---
<a href="https://app.joggr.io/app/documents/110fa0bb-3e32-430e-ad53-386f9f8886a9/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(110fa0bb-3e32-430e-ad53-386f9f8886a9):end -->