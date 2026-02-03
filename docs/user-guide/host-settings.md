# Host Settings

This page contains settings for Linux servers, these instructions are agnostic of the Linux
distribution used by the servers. The commands use the `ip` utility from the `iproute2` package.
These settings **do not persist across reboots**. Consult the documentation from
the Linux distribution for guides on how to persist the settings used on the
server. For example, [Netplan][netplan] or [Network Manager][nmanager]. For
additional details on options and behavior, consult the [kernel bonding driver][bonding] documentation.

[nmanager]: https://networkmanager.dev/docs/admins/
[netplan]: https://documentation.ubuntu.com/server/explanation/networking/configuring-networks/index.html

## Multi-homing

ESLAG (EVPN Multi-Homing) is the recommended way to provide device redundancy.
A server connects to multiple switches (up to 4) without requiring the switches
to be directly connected to each other. The host must configure its ports using
LACP (IEEE 802.3ad).

### Server Settings

The supported server-side setting for bonding is `802.3ad`, with hashing policy
`layer2` or `layer2+3`. `layer2+3` transmit hashing is the recommended
setting for the overwhelming majority of scenarios. 
To configure this in Linux:

``` bash
sudo ip link add $bond_name type bond miimon 50 mode 802.3ad layer2+3
sudo ip link set $slave1_name master $bond_name
sudo ip link set $slave2_name master $bond_name
```

The `miimon 100` indicates that the bonding driver will use `miimon` to
determine if the link is `up`, and it will poll every 50 milliseconds.

`layer2` or `layer2+3` is the hashing mode, which controls the input into the
hash function. See the [kernel bonding driver][bonding] documentation for 
additional details.

After the bond has been created, it can receive a DHCP address or be
statically assigned, for example:

```bash
sudo ip addr add 10.30.10.10/24 dev bond0
```

To check the status of this bond:

```bash
cat /proc/net/bonding/bond0
```

## VLANs

A Linux host is capable of receiving tagged and untagged traffic. Tagged
traffic is traffic that has the VLAN (802.1q) header intact, untagged traffic
has the VLAN header removed as it exits the switch.

The Open Network Fabric is capable of emitting tagged and untagged traffic. The
setting to change whether traffic is tagged or untagged is on the
[VPCAttahcment](vpcs.md#vpcattachment), specifically the `nativeVLAN` field.
The default value of this field is `false`, meaning the fabric will emit tagged
traffic. If a port emits tagged traffic, it means that the Linux host must handle 
the tag. This is accomplished by creating a link layer interface on the host for the tag:

```bash
sudo ip link add link enp2s1 name enp2s1.1001 type vlan id 1001
```
The name `enp2s1.1001` is by convention; it can be customized. The `vlan` in
this example is `1001` and was created when the subnet was created inside the
[VPC](vpcs.md#vpc). 

When the `nativeVLAN` field is `true`, the switch will remove the 802.1q tag
from the packet as it exits the switch. When a Linux server is attached to this
port, there is no need to create an additional link layer device.

### Multiple VLANs on a port

At times, it is desirable to configure a single port that emits more than one
VLAN tag, which is called VLAN trunking. To create a trunk port, attach the VPC
subnet to the  desired port, multiple VPC subnets can be connected to a single
connection object:

```bash
kubectl fabric vpc attach --vpc-subnet vpc-1/default --connection server-1--leaf-1
kubectl fabric vpc attach --vpc-subnet vpc-2/default --connection server-1--leaf-1
```

[bonding]: https://www.kernel.org/doc/html/latest/networking/bonding.html

## HostBGP container

If using [HostBGP subnets](vpcs.md#hostbgp-subnets), BGP should be running on the host server and
an appropriate configuration should be applied. To facilitate these steps, Hedgehog provides a
docker container which automatically starts [FRR](https://docs.frrouting.org/en/latest/) with
a valid configuration to join the Fabric.

As a first step, users should download the docker image from our registry:
```bash
docker pull ghcr.io/githedgehog/host-bgp:v0.1.1
```

The container should then be run with host networking (so that FRR can communicate with the leaves
using the host's interfaces) and in privileged mode. Additionally, a few input parameters are required:

- an optional ASN to use for BGP - if not specified the container will use ASN 64999;
- a comma-separated list of interfaces over which to establish unnumbered BGP sessions with leaves;
- a space-separated list of Virtual IPs (or VIPs) to be advertised to the leaves; these should have
  a prefix length of /32 and be part of the subnet the host is attaching to.

As an example, the command might look something like this:
```bash
docker run --network=host --privileged --rm --detach --name hostbgp ghcr.io/githedgehog/host-bgp:v0.1.1 enp2s1,enp2s2 10.100.34.5/32
```

With the above command, BGP sessions would be created on interfaces `enp2s1` and `enp2s2`,
using ASN 64999 (the default), the address `10.100.34.5/32` will be configured on the loopback of
the host server and it will be advertised to the leaves.

To further modify the configuration or to troubleshoot the state of the system, an
expert user can invoke the FRR CLI using the following command:
```bash
docker exec -it hostbgp vtysh
```

To stop the container, just run the following command:
```bash
docker stop -t 1 hostbgp
```

Note that stopping the docker container does not currently remove the VIPs from the loopback.
If needed, they can be removed manually, for example using iproute2:
```bash
sudo ip address delete dev lo <VIP>
```
