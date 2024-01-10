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
# System Requirements

- Fast SSDs for system/root and K8s & container runtime forlders are required for stable work
- SSDs are mandatory for Control Nodes
- Minimal (non-HA) setup is a single Contol Node
- (Future) Full (HA) setup is at least 3 Control Nodes
- (Future) Extra nodes could be used for things like Logging, Monitoring, Alerting stack and etc.

## Non-HA (minimal) setup - 1 Control Node

- Control Node runs non-HA K8s Contol Plane installation with non-HA Hedgehog Fabric Control Plane on top of it
- Not recommended for more then 10 devices participating in the Hedgehog Fabric or production deployments

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 4       | 8           |
| RAM  | 12 GB   | 16 GB       |
| Disk | 100 GB  | 250 GB      |

## (Future) HA setup - 3+ Control Nodes (per node)

- Each Contol Node runs part of the HA K8s Control Plane installation with Hedgehog Fabric Control Plane on top of it in
  HA mode as well
- Recommended for all cases where more then 10 devices participating in the Hedgehog Fabric

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 4       | 8           |
| RAM  | 12 GB   | 16 GB       |
| Disk | 100 GB  | 250 GB      |

## Device participating in the Hedgehog Fabric (e.g. switch)

- (Future) Each participating device is part of the K8s cluster, so, it run K8s kubelet
- Additionally it run Hedgehog Fabric Agent that controls devices configuration

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 1       | 2           |
| RAM  | 1 GB    | 1.5 GB      |
| Disk | 5 GB    | 10 GB       |

<!-- @joggr:editLink(e5647ea8-4fef-4251-9a78-97e353abe161):start -->
---
<a href="https://app.joggr.io/app/documents/e5647ea8-4fef-4251-9a78-97e353abe161/edit" alt="Edit doc on Joggr">
  <img src="https://storage.googleapis.com/joggr-public-assets/github/badges/edit-document-badge.svg" />
</a>
<!-- @joggr:editLink(e5647ea8-4fef-4251-9a78-97e353abe161):end -->