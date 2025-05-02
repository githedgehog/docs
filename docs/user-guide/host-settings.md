# Host Settings

This page contains settings for Linux servers, these instructions are agnostic of the Linux
distribution used by the servers. The commands use the `ip` utility from the `iproute2` package.
These settings **do not persist across reboots**. Consult the documentation from
the Linux distribution for guides on how to persist the settings used on the
server. For example, [Netplan][netplan] or [Network Manager][nmanager]. For
additional details on options and behavior, consult the [kernel bonding driver][bonding] documentation.

[nmanager]: https://networkmanager.dev/docs/admins/
[netplan]: https://documentation.ubuntu.com/server/explanation/networking/configuring-networks/index.html

## MCLAG / ESLAG

The multi-chassis LAG architecture is a way to provide device redundancy
in a network architecture. At the physical layer, an MCLAG topology is a single
server connected to two different switches and, those switches are directly connected
to each other in addition to being connected to the rest of the fabric.

ESLAG is a similar technology to MCLAG, with the beneficial difference that the
switches do not need to be directly connected to each other. There can be up to 4
switches in an ESLAG group, whereas MCLAG is always two switches.

Regardless of whether MCLAG or ESLAG is chosen, the host must configure its two
(or more) ports using LACP (IEEE 802.3ad).

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


## LAG, Bonding, Teaming, Bundling

A LAG configuration can be used to increase the bandwidth to and from an end
host. For example, if a server has two 25 Gbps ports, the ports can be bonded so
they will have an aggregate 50 Gbps of available bandwidth. At the physical
layer, two cables are going from the server to a single switch.

To enable fast detection of faults, `802.3ad` is the supported mode for bonds
attaching to the Open Network Fabric. The steps to configure the bond are the
same as the [above server settings](#server-settings)

The kernel bonding driver documentation discusses other modes for bonding. 
Several of those modes don't require cooperation on the switch side, so there 
is no fabric configuration needed. The primary concerns for using these modes 
are out-of-order TCP delivery, fault detection, and correction time.

## Active / Passive Fault Tolerance

Some networking equipment doesn't support MCLAG or ESLAG. In this case, to
enable fault-tolerant availability, configure a bond on the Linux server in
active / standby mode. In this topology, a link is connected from
server-1 to switch-1, and another link is connected from server-1 to switch-2.
There is neither [MCLAG connection](connections.md#mclag) nor [switch
group](devices.md#redundancy-groups) configuration applied to the
switches. When adding these links to the fabric via the `kubectl` command or
the wiring diagram, use the [unbundled](connections.md#unbundled) connection
kind.

### Active / Passive Bond Settings

The IP addresses used in the following commands are examples. On the host:

1. Create a bond: 

``` bash
sudo ip link add bond0 type bond mode active-backup miimon 50 num_grat_arp 5 primary enp2s1
```
2. Add the member interfaces to the bond:

``` bash
sudo ip link set link enp2s1 master bond0
sudo ip link set link enp2s2 master bond0
```
3. Add an address to the bond:

``` bash
sudo ip addr add 10.30.10.10/24 dev bond0
```
4. Make the bond  the default route:

```bash
sudo ip route add default via 10.30.10.1
```

Print the link layer information for the interfaces to see that the same MAC
address is on all 3 interfaces: bond0, enp2s1,enp2s2:

``` console 
core@server-1 ~ $ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp2s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP mode DEFAULT group default qlen 1000
    link/ether a6:eb:64:de:95:92 brd ff:ff:ff:ff:ff:ff permaddr a0:36:9f:3f:1a:e8
3: enp2s2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP mode DEFAULT group default qlen 1000
    link/ether a6:eb:64:de:95:92 brd ff:ff:ff:ff:ff:ff permaddr 14:02:ec:7f:3a:3c
4: enp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 0c:20:12:fe:01:00 brd ff:ff:ff:ff:ff:ff
10: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether a6:eb:64:de:95:92 brd ff:ff:ff:ff:ff:ff
13: bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether a6:eb:64:de:95:92 brd ff:ff:ff:ff:ff:ff
```

Confirm that the bonding driver is reporting the selected primary interface:

```console
core@server-1 ~ $ cat /proc/net/bonding/bond0

Ethernet Channel Bonding Driver: v6.6.74-flatcar

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: enp2s1 (primary_reselect always)
Currently Active Slave: enp2s1
MII Status: up
MII Polling Interval (ms): 50
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

Slave Interface: enp2s1
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: a0:36:9f:3f:1a:e8
Slave queue ID: 0

Slave Interface: enp2s2
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 14:02:ec:7f:3a:3c
Slave queue ID: 0
```

### Failure Scenarios
When `miimon` detects that the primary member interface is no longer `up`, the bonding
driver will send five gratuitous ARP messages via the secondary member interface to notify the switch
that the IP address is now on a new switch. The fabric will start routing
traffic to this location, and the host will start receiving traffic.

If the `miimon` polling determines that the primary member interface link is
`up`, then the bonding driver will switch back to the primary member interface. 
The `primary_reselect` behavior is configurable, see the [kernel bonding driver][bonding] documentation
 for additional details.

The changeover process will result in dropped packets, but it should not result
in TCP timeouts. 

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

