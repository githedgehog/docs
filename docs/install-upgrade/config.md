# Fabric Configuration

* `--fabric-mode <mode-name` (`collapsed-core` or `spine-leaf`) - Fabric mode to use, default is `spine-leaf`; in case
    of `collapsed-core` mode, there will be no VXLAN configured and only 2 switches will be used
* `--ntp-servers <servers>`- Comma-separated list of NTP servers to use, default is
    `time.cloudflare.com,time1.google.com,time2.google.com,time3.google.com,time4.google.com`, it'll be used for both
    control nodes and switches
* `--dhcpd <mode-name>` (`isc` or `hedgehog`) - DHCP server to use, default is `isc`; `hedgehog` DHCP server enables
    use of on-demand DHCP for multiple IPv4/VLAN namespaces and overlapping IP ranges as well as adds DHCP leases
    into the Fabric API

You can find more information about using `hhfab init` in the help message by running it with `--help` flag.