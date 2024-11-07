# System Requirements

## Out of Band Management Network

In order to provision and manage the switches that comprise the fabric, an out of band switch must also be installed. This network is to be used exclusively by the control node and the fabric switches, no other access is permitted. This switch (or switches) is not managed by the fabric. It is recommended that this switch have at least a 10GbE port and that port connect to the control node.

## Control Node

- Fast SSDs for system/root is mandatory for Control Nodes
    - NVMe SSDs are recommended
    - DRAM-less NAND SSDs are not supported (e.g. Crucial BX500)
- 10 GbE port for connection to management network is recommended
- Minimal (non-HA) setup is a single Control Node
- (Future) Full (HA) setup is at least 3 Control Nodes
- (Future) Extra nodes could be used for things like Logging, Monitoring, Alerting stack, and more

In internal testing Hedgehog uses a server with the following specifications:

- CPU - AMD EPYC 4344P 
- Memory - 32 GiB DDR5 ECC 4800MT/s
- Storage - PCIe Gen 4 NVMe M.2 400GB
- Network - AOC-STG-i4S Intel X710-BM1 controller
- Motherboard - H13SAE-MF


### Non-HA (minimal) setup - 1 Control Node

- Control Node runs non-HA Kubernetes Control Plane installation with non-HA Hedgehog Fabric Control Plane on top of it
- Not recommended for more then 10 devices participating in the Hedgehog Fabric or production deployments

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 6       | 8           |
| RAM  | 16 GB   | 32 GB       |
| Disk | 150 GB  | 250 GB      |

### (Future) HA setup - 3+ Control Nodes (per node)

- Each Control Node runs part of the HA Kubernetes Control Plane installation with Hedgehog Fabric Control Plane on top
  of it in HA mode as well
- Recommended for all cases where more than 10 devices participating in the Hedgehog Fabric

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 6       | 8           |
| RAM  | 16 GB   | 32 GB       |
| Disk | 150 GB  | 250 GB      |

### Reference Control Node Configuration

- AMD EPYC 4344P (8C/16T, 3.8 GHz, 32 MB L3, 65W, single socket)
- 32 GB DDR5-4800 ECC UDIMM (2 x 16 GB)
- Micron 7450 MAX 400GB NVMe

## Device participating in the Hedgehog Fabric (e.g. switch)

- (Future) Each participating device is part of the Kubernetes cluster, so it runs Kubernetes kubelet
- Additionally, it runs the Hedgehog Fabric Agent that controls devices configuration

Following resources should be available on a device to run in the Hedgehog Fabric (after other software such as SONiC usage):

|      | Minimal | Recommended |
| ---- | ------- | ----------- |
| CPU  | 1       | 2           |
| RAM  | 1 GB    | 1.5 GB      |
| Disk | 5 GB    | 10 GB       |
