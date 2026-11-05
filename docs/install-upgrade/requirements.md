# System Requirements

## Out of Band Management Network

In order to provision and manage the switches and gateways that comprise the fabric, an out of band switch must also be
installed. This network is to be used exclusively by the control node and the fabric switches, no other access is
permitted. This switch (or switches) is not managed by the fabric. It is recommended that this switch have at least a
10GbE port and that port connect to the control node.

## Notes

- x86 CPU Architecture
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

Minimum system requirements depend on the number of switches in the fabric:

| Switches  | CPU cores | CPU examples                | Memory | Storage |
|-----------|-----------|-----------------------------|--------|---------|
| up to 50  | 8         | AMD EPYC 4345P or EPYC 9015 | 32 GB  | 800 GB  |
| up to 100 | 12        | AMD EPYC 4465P or EPYC 9135 | 48 GB  | 800 GB  |
| up to 200 | 16        | AMD EPYC 4565P or EPYC 9135 | 64 GB  | 1.6 TB  |
| up to 500 | 32        | AMD EPYC 9355P              | 128 GB | 1.6 TB  |

- CPU cores are physical cores, SMT (Hyper-Threading) threads don't count
- Memory - DDR5 ECC, at least 2 memory channels should be populated
- Storage - PCIe Gen 4 or newer enterprise NVMe SSD (e.g. Micron MAX line)
    - Mixed-use SSD rated for at least 3 DWPD (drive writes per day) is required, the control plane writes
      continuously, roughly 0.5 TB per day per 100 switches
    - Fast NVMe SSD is required (fsync latency under 10 ms), DRAM-less NAND SSDs are not supported
- NICs
    - at least 1 to connect to outside world (ssh to control node, API access, etc), 1G min is okay
    - at least 1 to connect to the OOB management network
    - 1G for small deployments (10-15 switches)
    - 10G is recommended for bigger ones (15+ switches)
- Redundant PSU is highly recommended
- Note: many 1U systems are suitable for that but would have non-redundant PSU

## Gateway Node

All gateway nodes require IOMMU support enabled in the firmware (Intel VT-d or AMD-Vi), the installation fails
without it.

Minimum system requirements for bandwidth under 50Gb/s:

- CPU - AMD EPYC 4564P (16 cores)
- Memory - 2 x 32GiB DDR5 ECC 5600MHz (exactly 2 channels should be populated)
- Storage - PCIe Gen 4 NVMe M.2 400GB (e.g. Micron MAX line)
    - Fast NVMe SSD is required, DRAM-less NAND SSDs are not supported
- NICs
    - at least 1 to connect to the OOB management network (1G is enough)
    - single NVIDIA ConnectX-7 specifically 2x200G port versions to connect to the fabric
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
