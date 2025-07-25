# System Requirements

## Out of Band Management Network

In order to provision and manage the switches and gateways that comprise the fabric, an out of band switch must also be
installed. This network is to be used exclusively by the control node and the fabric switches, no other access is
permitted. This switch (or switches) is not managed by the fabric. It is recommended that this switch have at least a
10GbE port and that port connect to the control node.

## Notes

- Only UEFI is supported
- Fast SSDs for system/root is mandatory for Control Nodes
    - NVMe SSDs are recommended
    - DRAM-less NAND SSDs are not supported (e.g. Crucial BX500)
- 10 GbE port for connection to management network is recommended
- TPM is recommended
- Minimal (non-HA) setup is a single Control Node
- (Future) Full (HA) setup is at least 3 Control Nodes
- (Future) Extra nodes could be used for things like Logging, Monitoring, Alerting stack, and more

## Control Node

Minimum system requirements for the fabric deployments under 50 switches:

- CPU - AMD EPYC 4344P (8 cores)
    - newer generation and/or more cores like 4345P (8 core) or 4465P (12 cores) is good
- Memory - 2 x 16 GiB DDR5 ECC 5600MHz (exactly 2 channels should be populated)
- Storage - PCIe Gen 4 NVMe M.2 400GB (e.g. Micron MAX line)
    - Fast NVMe SSD is required, DRAM-less NAND SSDs are not supported
- NICs
    - at least 1 to connect to outside world (ssh to control node, API access, etc), 1G min is okay
    - at least 1 to connect to the OOB management network
    - 1G for small deployments (10-15 switches)
    - 10G is recommended for bigger ones (15+ switches)
- Redundant PSU is highly recommended
- Note: many 1U systems are suitable for that but would have non-redundant PSU

For the fabric deployments over 50 switches it's required to increase CPU/RAM/Storage:

- CPU - AMD EPYC 4565P or 4564P (16 cores)
- Memory - 2 x 32GiB DDR5 ECC 5600MHz (exactly 2 channels should be populated)
- Storage - PCIe Gen 4 NVMe M.2 800GB (e.g. Micron MAX line)

## Gateway Node

Minimum system requirements for bandwidth under 50Gb/s:

- CPU - AMD EPYC 4564P (16 cores)
- Memory - 2 x 32GiB DDR5 ECC 5600MHz (exactly 2 channels should be populated)
- Storage - PCIe Gen 4 NVMe M.2 400GB (e.g. Micron MAX line)
    - Fast NVMe SSD is required, DRAM-less NAND SSDs are not supported
- NICs
    - at least 1 to connect to the OOB management network (1G is enough)
    - single NVIDIA ConnectX-6 specifically 2 ports versions to connect to the fabric
        - crypto-enabled is recommended
- Redundant PSU is highly recommended
- Note: many 1U systems are suitable for that but would have non-redundant PSU

Minimum system requirements for more then 50Gb/s bandwidth, up to 200Gb/s:

- CPU - AMD EPYC 9355P (32 core)
- Memory - 12 x 16GB DDR5 6400MHz ECC (exactly 12 channels should be populated)
- Storage - PCIe Gen 4 NVMe M.2 400GB (e.g. Micron MAX line)
    - Fast NVMe SSD is required, DRAM-less NAND SSDs are not supported
- NICs
    - at least 1 to connect to the OOB management network (1G is enough)
    - single NVIDIA ConnectX-7 specifically 2x200G versions to connect to the fabric
        - crypto-enabled is recommended
- Redundant PSU is highly recommended
