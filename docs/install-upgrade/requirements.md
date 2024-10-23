# System Requirements

## Control Node
- Fast SSDs for system/root as well as Kubernetes and container runtime folders are required for stable work
- SSDs are mandatory for Control Nodes
- 10 GbE port for connection to management network
- Minimal (non-HA) setup is a single Control Node
- (Future) Full (HA) setup is at least 3 Control Nodes
- (Future) Extra nodes could be used for things like Logging, Monitoring, Alerting stack, and more


## Out of Band Management Network

In order to provision and manage the switches that comprise the fabric, an out of band switch must also be installed. This network is to be used exclusively by the control node and the fabric switches, no other access is permitted. This switch is not manged by the fabric. It is recommended that this switch have at least a 10GbE port and that port connect to the control node.


## Non-HA (minimal) setup - 1 Control Node

- Control Node runs non-HA Kubernetes Control Plane installation with non-HA Hedgehog Fabric Control Plane on top of it
- Not recommended for more then 10 devices participating in the Hedgehog Fabric or production deployments

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 4       | 8           |
| RAM  | 12 GB   | 16 GB       |
| Disk | 100 GB  | 250 GB      |

## (Future) HA setup - 3+ Control Nodes (per node)

- Each Control Node runs part of the HA Kubernetes Control Plane installation with Hedgehog Fabric Control Plane on top
  of it in HA mode as well
- Recommended for all cases where more than 10 devices participating in the Hedgehog Fabric

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 4       | 8           |
| RAM  | 12 GB   | 16 GB       |
| Disk | 100 GB  | 250 GB      |

## Device participating in the Hedgehog Fabric (e.g. switch)

- (Future) Each participating device is part of the Kubernetes cluster, so it runs Kubernetes kubelet
- Additionally, it runs the Hedgehog Fabric Agent that controls devices configuration

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 1       | 2           |
| RAM  | 1 GB    | 1.5 GB      |
| Disk | 5 GB    | 10 GB       |
