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
docker pull ghcr.io/githedgehog/host-bgp
```

The container should then be run with host networking (so that FRR can communicate with the leaves
using the host's interfaces) and in privileged mode. Additionally, a few input parameters are required:

- an optional ASN to use in BGP. If present, it should be the first parameter; if not specified, the container will use ASN 64999
- one or more VPC subnets with their related parameters, in the format
  `<VPC-SUBNET-NAME>:v=<VLAN>:i=<INTERFACE1>[:i=<INTERFACE2>...]:a=<ADDRESS1>[:a=<ADDRESS2>...]`, where:
    - `<VPC-SUBNET-NAME>` is just a mnemonic ID for the VPC subnet we want to attach to.
      It can be anything as long as it is a legal name for a route-map or prefix-list in FRR.
    - `v=<VLAN>` is the VLAN ID to be used for the VPC; use 0 for untagged.
    - `i=<INTERFACE1>` is an interface to be used to establish a BGP unnumbered session with a
      Fabric leaf; if a VLAN ID was specified, a corresponding VLAN interface will be created using
      the provided interface as the master device.
    - `a=<ADDRESS1>` is the Virtual IP (or VIP) to be advertised to the leaves; it should have
      a prefix length of /32 and be part of the subnet the host is attaching to.

As an example, the command might look something like this:
```bash
docker run --network=host --privileged --rm --detach --name hostbgp ghcr.io/githedgehog/host-bgp 64307 vpc-01:v=1001:i=enp2s1:i=enp2s2:a=10.100.34.5/32
```
!!! note
    With the above command, any output produced by the container will not be visible from the terminal
    where it was started. Verify that the container is running correctly with `docker ps`, or examine
    the logs of the container with `docker logs hostbgp` to investigate a failure.

With the above command:

- VLAN interfaces `enp2s1.1001` and `enp2s2.1001` would be created, if not already existing
- BGP unnumbered sessions would be created on those same interfaces, using ASN 64307
- the address `10.100.34.5/32` would be configured on the loopback of the host server and it would be advertised to the leaves

To further modify the configuration or to troubleshoot the state of the system, an
expert user can invoke the FRR CLI using the following command:
```bash
docker exec -it hostbgp vtysh
```

For example, one could use vtysh to verify the configuration generated with the above command:
```bash
$ docker exec -t hostbgp vtysh -c "show run"
Building configuration...

Current configuration:
!
frr version 10.5.1_git
frr defaults traditional
hostname server-04
service integrated-vtysh-config
!
ip prefix-list vpc-01 seq 5 permit 10.100.34.5/32
!
route-map vpc-01 permit 10
 match ip address prefix-list vpc-01
exit
!
interface lo
 ip address 10.100.34.5/32
exit
!
router bgp 64307
 no bgp ebgp-requires-policy
 bgp bestpath as-path multipath-relax
 timers bgp 3 9
 neighbor enp2s1.1001 interface remote-as external
 neighbor enp2s2.1001 interface remote-as external
 !
 address-family ipv4 unicast
  network 10.100.34.5/32
  neighbor enp2s1.1001 route-map vpc-01 out
  neighbor enp2s2.1001 route-map vpc-01 out
  maximum-paths 4
 exit-address-family
exit
!
end
```

To stop the container, just run the following command:
```bash
docker stop -t 1 hostbgp
```

Note that stopping the docker container does not currently remove the VIPs from the loopback, nor
does it delete the VLAN interfaces. If needed, these should be removed manually; for example,
using iproute2 and the reference command above, one could run:
```bash
sudo ip address delete dev lo 10.100.34.5/32
sudo ip link delete dev enp2s1.1001
sudo ip link delete dev enp2s2.1001
```

Users should consider automating the startup of the hostbgp container at system boot up, to make
sure that connectivity is restored in case of a reboot.

### Example: multi-VPC multi-homed server

Let's assume that `server-03` is attached to both `leaf-01` and `leaf-02` with unbundled connections
`server-03--unbundled--leaf-01` and `server-03--unbundled--leaf-02`, and that we want it to be part
of two separate VPCs using host-BGP. We can create the VPCs and attachments e.g. from the control node
using the Fabric `kubectl` plugin:

```bash
core@control-1 ~ $ kubectl fabric vpc create --name=vpc-01 --subnet=10.0.1.0/24 --vlan=1001 --host-bgp=true
10:04:09 INF VPC created name=vpc-01
core@control-1 ~ $ kubectl fabric vpc create --name=vpc-02 --subnet=10.0.2.0/24 --vlan=1002 --host-bgp=true
10:04:24 INF VPC created name=vpc-02
core@control-1 ~ $ kubectl fabric vpc attach --name=s3-v1-l1 --conn=server-03--unbundled--leaf-01 --subnet=vpc-01/default
10:05:59 INF VPCAttachment created name=s3-v1-l1
core@control-1 ~ $ kubectl fabric vpc attach --name=s3-v1-l2 --conn=server-03--unbundled--leaf-02 --subnet=vpc-01/default
10:06:08 INF VPCAttachment created name=s3-v1-l2
core@control-1 ~ $ kubectl fabric vpc attach --name=s3-v2-l1 --conn=server-03--unbundled--leaf-01 --subnet=vpc-02/default
10:06:24 INF VPCAttachment created name=s3-v2-l1
core@control-1 ~ $ kubectl fabric vpc attach --name=s3-v2-l2 --conn=server-03--unbundled--leaf-02 --subnet=vpc-02/default
10:06:33 INF VPCAttachment created name=s3-v2-l2
```

Then we can configure `server-03` using the provided container:

```bash
docker run --network=host --privileged --rm --detach --name hostbgp ghcr.io/githedgehog/host-bgp vpc-01:v=1001:i=enp2s1:i=enp2s2:a=10.0.1.3/32 vpc-02:v=1002:i=enp2s1:i=enp2s2:a=10.0.2.3/32
```

This will generate the following FRR configuration:
```
!
ip prefix-list vpc-01 seq 5 permit 10.0.1.3/32
ip prefix-list vpc-02 seq 5 permit 10.0.2.3/32
!
route-map vpc-01 permit 10
 match ip address prefix-list vpc-01
exit
!
route-map vpc-02 permit 10
 match ip address prefix-list vpc-02
exit
!
interface lo
 ip address 10.0.1.3/32
 ip address 10.0.2.3/32
exit
!
router bgp 64999
 no bgp ebgp-requires-policy
 bgp bestpath as-path multipath-relax
 timers bgp 3 9
 neighbor enp2s1.1001 interface remote-as external
 neighbor enp2s1.1002 interface remote-as external
 neighbor enp2s2.1001 interface remote-as external
 neighbor enp2s2.1002 interface remote-as external
 !
 address-family ipv4 unicast
  network 10.0.1.3/32
  network 10.0.2.3/32
  neighbor enp2s1.1001 route-map vpc-01 out
  neighbor enp2s1.1002 route-map vpc-02 out
  neighbor enp2s2.1001 route-map vpc-01 out
  neighbor enp2s2.1002 route-map vpc-02 out
  maximum-paths 4
 exit-address-family
exit
!
```

And we can verify on either of the leaves attached to `server-03` that VIPs are only
learned in the VPC they belong to:
```
leaf-01# show ip route vrf VrfVvpc-01
Codes:  K - kernel route, C - connected, S - static, B - BGP, O - OSPF, A - attached-host
        > - selected route, * - FIB route, q - queued route, r - rejected route, b - backup
       Destination        Gateway                                                                    Dist/Metric   Last Update
--------------------------------------------------------------------------------------------------------------------------------
 B>*   10.0.1.3/32        via fe80::e20:12ff:fefe:401     Ethernet1.1001                             20/0          00:09:43 ago
leaf-01# show ip route vrf VrfVvpc-02
Codes:  K - kernel route, C - connected, S - static, B - BGP, O - OSPF, A - attached-host
        > - selected route, * - FIB route, q - queued route, r - rejected route, b - backup
       Destination        Gateway                                                                    Dist/Metric   Last Update
--------------------------------------------------------------------------------------------------------------------------------
 B>*   10.0.2.3/32        via fe80::e20:12ff:fefe:401     Ethernet1.1002                             20/0          00:09:47 ago
leaf-01#
```
