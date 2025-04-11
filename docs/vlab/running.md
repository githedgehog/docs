# Running VLAB

Make sure to follow the prerequisites and check system requirements in the [VLAB Overview](overview.md) section
before running VLAB.

## Initialize VLAB

First, initialize Fabricator by running `hhfab init --dev`. This command creates the `fab.yaml` file, which is the main configuration file for the fabric. This command supports several customization options that are listed in the output of `hhfab init --help`.

```console
ubuntu@docs:~$ hhfab init --dev
11:26:52 INF Hedgehog Fabricator version=v0.36.1
11:26:52 INF Generated initial config
11:26:52 INF Adjust configs (incl. credentials, modes, subnets, etc.) file=fab.yaml
11:26:52 INF Include wiring files (.yaml) or adjust imported ones dir=include
```
## VLAB Topology

By default, `hhfab init` creates 2 spines, 2 MCLAG leaves, 2 ESLAG leaves and 1 non-MCLAG leaf with 2 fabric connections (between each spine and leaf), 2 MCLAG peer links and 2 MCLAG session links as well as 2 loopbacks per leaf for implementing VPC loopback workaround. It will also generate a VM to emulate an [External](../user-guide/external.md) device and two connections to it from the ESLAG leaves. To generate the preceding topology, `hhfab vlab gen`. You can also configure the number of spines, leafs, connections, and so on. For example, flags `--spines-count` and `--mclag-leafs-count` allow you to set the number of spines and MCLAG leaves, respectively. For complete options, `hhfab vlab gen -h`.

```console
ubuntu@docs:~$ hhfab vlab gen
10:38:06 INF Hedgehog Fabricator version=v0.36.1
10:38:06 INF Building VLAB wiring diagram fabricMode=spine-leaf
10:38:06 INF >>> spinesCount=2 fabricLinksCount=2
10:38:06 INF >>> eslagLeafGroups=2
10:38:06 INF >>> mclagLeafsCount=2 mclagSessionLinks=2 mclagPeerLinks=2
10:38:06 INF >>> orphanLeafsCount=1 vpcLoopbacks=2
10:38:06 INF >>> mclagServers=2 eslagServers=2 unbundledServers=1 bundledServers=1
10:38:06 INF >>> externalCount=1 externalMclagConnCount=0 externalEslagConnCount=2 externalOrphanConnCount=0
10:38:06 INF Generated wiring file name=vlab.generated.yaml
```
You can jump [to the instructions](#build-the-installer-and-start-vlab) to start VLAB, or see the next section for customizing the topology.

### Collapsed Core
If a Collapsed Core topology is desired, after the `hhfab init --dev` step, edit the resulting `fab.yaml` file and change the `mode: spine-leaf` to `mode: collapsed-core`:

```console
ubuntu@docs:~$ hhfab vlab gen
11:21:02 INF Hedgehog Fabricator version=v0.36.1
11:21:02 INF Building VLAB wiring diagram fabricMode=collapsed-core
11:21:02 INF >>> mclagLeafsCount=2 mclagSessionLinks=2 mclagPeerLinks=2
11:21:02 INF >>> orphanLeafsCount=0 vpcLoopbacks=2
11:21:02 INF >>> mclagServers=2 eslagServers=0 unbundledServers=1 bundledServers=1
11:21:02 INF >>> externalCount=1 externalMclagConnCount=2 externalEslagConnCount=0 externalOrphanConnCount=0
11:21:02 INF Generated wiring file name=vlab.generated.yaml
```

### Custom Spine Leaf
Or you can run custom topology with 2 spines, 4 MCLAG leaves, 2 non-LAG leaves and no externals using flags:

```console
ubuntu@docs:~$ hhfab vlab gen --mclag-leafs-count 4 --orphan-leafs-count 2 --externals 0
12:03:39 INF Hedgehog Fabricator version=v0.36.1
12:03:39 INF Building VLAB wiring diagram fabricMode=spine-leaf
12:03:39 INF >>> spinesCount=2 fabricLinksCount=2
12:03:39 INF >>> eslagLeafGroups=""
12:03:39 INF >>> mclagLeafsCount=4 mclagSessionLinks=2 mclagPeerLinks=2
12:03:39 INF >>> orphanLeafsCount=2 vpcLoopbacks=2
12:03:39 INF >>> mclagServers=2 eslagServers=0 unbundledServers=1 bundledServers=1
12:03:39 INF >>> externalCount=0 externalMclagConnCount=0 externalEslagConnCount=0 externalOrphanConnCount=0
12:03:39 INF Generated wiring file name=vlab.generated.yaml
```

Additionally, you can pass extra Fabric configuration items using flags on `init` command or by passing a configuration
file. For more information, refer to the [Fabric Configuration](../install-upgrade/config.md) section.

Once you have initialized the VLAB, download the artifacts and build the installer using `hhfab build`. This command
automatically downloads all required artifacts from the OCI registry and builds the installer and all other
prerequisites for running the VLAB.

## Build the Installer and Start VLAB

To build and start the virtual machines, use `hhfab vlab up`. For successive runs, use the `--kill-stale` flag to ensure that any virtual machines from a previous run are gone. `hhfab vlab up` runs in the foreground and does not return, which allows you to stop all VLAB VMs by simply pressing `Ctrl + C`.
```console
ubuntu@docs:~$ hhfab vlab up
11:48:22 INF Hedgehog Fabricator version=v0.36.1
11:48:22 INF Wiring hydrated successfully mode=if-not-present
11:48:22 INF VLAB config created file=vlab/config.yaml
11:48:22 INF Downloader cache=/home/ubuntu/.hhfab-cache/v1 repo=ghcr.io prefix=githedgehog
11:48:22 INF Building installer control=control-1
11:48:22 INF Adding recipe bin to installer control=control-1
11:48:24 INF Adding k3s and tools to installer control=control-1
11:48:25 INF Adding zot to installer control=control-1
11:48:25 INF Adding cert-manager to installer control=control-1
11:48:26 INF Adding config and included wiring to installer control=control-1
11:48:26 INF Adding airgap artifacts to installer control=control-1
11:48:36 INF Archiving installer path=/home/ubuntu/result/control-1-install.tgz control=control-1
11:48:45 INF Creating ignition path=/home/ubuntu/result/control-1-install.ign control=control-1
11:48:46 INF Taps and bridge are ready count=8
11:48:46 INF Downloader cache=/home/ubuntu/.hhfab-cache/v1 repo=ghcr.io prefix=githedgehog
11:48:46 INF Preparing new vm=control-1 type=control
11:48:51 INF Preparing new vm=server-01 type=server
11:48:52 INF Preparing new vm=server-02 type=server
11:48:54 INF Preparing new vm=server-03 type=server
11:48:55 INF Preparing new vm=server-04 type=server
11:48:57 INF Preparing new vm=server-05 type=server
11:48:58 INF Preparing new vm=server-06 type=server
11:49:00 INF Preparing new vm=server-07 type=server
11:49:01 INF Preparing new vm=server-08 type=server
11:49:03 INF Preparing new vm=server-09 type=server
11:49:04 INF Preparing new vm=server-10 type=server
11:49:05 INF Preparing new vm=leaf-01 type=switch
11:49:06 INF Preparing new vm=leaf-02 type=switch
11:49:06 INF Preparing new vm=leaf-03 type=switch
11:49:06 INF Preparing new vm=leaf-04 type=switch
11:49:06 INF Preparing new vm=leaf-05 type=switch
11:49:06 INF Preparing new vm=spine-01 type=switch
11:49:06 INF Preparing new vm=spine-02 type=switch
11:49:06 INF Starting VMs count=18 cpu="54 vCPUs" ram="49664 MB" disk="550 GB"
11:49:59 INF Uploading control install vm=control-1 type=control
11:53:39 INF Running control install vm=control-1 type=control
11:53:40 INF control-install: 01:53:39 INF Hedgehog Fabricator Recipe version=v0.36.1 vm=control-1
11:53:40 INF control-install: 01:53:39 INF Running control node installation vm=control-1
12:00:32 INF control-install: 02:00:31 INF Control node installation complete vm=control-1
12:00:32 INF Control node is ready vm=control-1 type=control
12:00:32 INF All VMs are ready

```
When the message `INF Control node is ready vm=control-1 type=control` from the installer's output means that the installer has finished. After this line
has been displayed, you can get into the control node and other VMs to watch the Fabric coming up and switches getting
provisioned. See [Accessing the VLAB](#accessing-the-vlab).

## Enable Outside connectivity from VLAB VMs

By default, all test server VMs are isolated and have no connectivity to the host or the Internet. You can configure
enable connectivity using `hhfab vlab up --restrict-servers=false` to allow the test servers to access the Internet and
the host. When you enable connectivity, VMs get a default route pointing to the host, which means that in case of the
VPC peering you need to configure test server VMs to use the VPC attachment as a default route (or just some specific
subnets).


## Accessing the VLAB

The `hhfab vlab` command provides `ssh` and `serial` subcommands to access the VMs. You can use `ssh` to get into the
control node and test servers after the VMs are started. You can use `serial` to get into the switch VMs while they are
provisioning and installing the software. After switches are installed you can use `ssh` to get into them.

You can select device you want to access or pass the name using the `--vm` flag.

```console
ubuntu@docs:~$ hhfab vlab ssh
Use the arrow keys to navigate: ↓ ↑ → ←  and / toggles search
SSH to VM:
  🦔 control-1
  server-01
  server-02
  server-03
  server-04
  server-05
  server-06
  leaf-01
  leaf-02
  leaf-03
  spine-01
  spine-02

----------- VM Details ------------
ID:             0
Name:           control-1
Ready:          true
Basedir:        .hhfab/vlab-vms/control-1
```
### Default credentials

Fabricator creates default users and keys for you to login into the control node and test servers as well as for the
SONiC Virtual Switches.

The default user with password-less sudo for the control node and test servers is `core` with password `HHFab.Admin!`.
The admin user with full access and password-less sudo for the switches is `admin` with password `HHFab.Admin!`.
The read-only, non-sudo user with access to the switch CLI is `op` with password `HHFab.Op!`.


## Use Kubectl to Interact with the Fabric
On the control node you have access to kubectl, Fabric CLI, and k9s to manage the Fabric. To view information
about the switches run `kubectl get agents -o wide`. After the control node is available it usually takes about 10-15 minutes for the
switches to get installed.

After the switches are provisioned, the command returns something like this:

```console
core@control-1 ~ $ kubectl get agents -o wide
NAME       ROLE          DESCR           HWSKU                      ASIC   HEARTBEAT   APPLIED   APPLIEDG   CURRENTG   VERSION   SOFTWARE                ATTEMPT   ATTEMPTG   AGE
leaf-01    server-leaf   VS-01 MCLAG 1   DellEMC-S5248f-P-25G-DPB   vs     30s         5m5s      4          4          v0.23.0   4.1.1-Enterprise_Base   5m5s      4          10m
leaf-02    server-leaf   VS-02 MCLAG 1   DellEMC-S5248f-P-25G-DPB   vs     27s         3m30s     3          3          v0.23.0   4.1.1-Enterprise_Base   3m30s     3          10m
leaf-03    server-leaf   VS-03           DellEMC-S5248f-P-25G-DPB   vs     18s         3m52s     4          4          v0.23.0   4.1.1-Enterprise_Base   3m52s     4          10m
spine-01   spine         VS-04           DellEMC-S5248f-P-25G-DPB   vs     26s         3m59s     3          3          v0.23.0   4.1.1-Enterprise_Base   3m59s     3          10m
spine-02   spine         VS-05           DellEMC-S5248f-P-25G-DPB   vs     19s         3m53s     4          4          v0.23.0   4.1.1-Enterprise_Base   3m53s     4          10m
```

The `Heartbeat` column shows how long ago the switch has sent the heartbeat to the control node. The `Applied` column
shows how long ago the switch has applied the configuration. `AppliedG` shows the generation of the configuration
applied. `CurrentG` shows the generation of the configuration the switch is supposed to run. Different values for
`AppliedG` and `CurrentG` mean that the switch is in the process of applying the configuration.

At that point Fabric is ready and you can use `kubectl` and `kubectl fabric` to manage the Fabric. You can find more
about managing the Fabric in the [Running Demo](demo.md) and [User Guide](../user-guide/overview.md) sections.

### Getting main Fabric objects

You can list the main Fabric objects by running `kubectl get` on the control node. You can find more details about
using the Fabric in the [User Guide](../user-guide/overview.md), [Fabric API](../reference/api.md) and
[Fabric CLI](../reference/cli.md) sections.

For example, to get the list of switches, run:

```console
core@control-1 ~ $ kubectl get switch
NAME       ROLE          DESCR           GROUPS   LOCATIONUUID                           AGE
leaf-01    server-leaf   VS-01 MCLAG 1            5e2ae08a-8ba9-599a-ae0f-58c17cbbac67   6h10m
leaf-02    server-leaf   VS-02 MCLAG 1            5a310b84-153e-5e1c-ae99-dff9bf1bfc91   6h10m
leaf-03    server-leaf   VS-03                    5f5f4ad5-c300-5ae3-9e47-f7898a087969   6h10m
spine-01   spine         VS-04                    3e2c4992-a2e4-594b-bbd1-f8b2fd9c13da   6h10m
spine-02   spine         VS-05                    96fbd4eb-53b5-5a4c-8d6a-bbc27d883030   6h10m
```

Similarly, to get the list of servers, run:

```console
core@control-1 ~ $ kubectl get server
NAME        TYPE      DESCR                        AGE
control-1   control   Control node                 6h10m
server-01             S-01 MCLAG leaf-01 leaf-02   6h10m
server-02             S-02 MCLAG leaf-01 leaf-02   6h10m
server-03             S-03 Unbundled leaf-01       6h10m
server-04             S-04 Bundled leaf-02         6h10m
server-05             S-05 Unbundled leaf-03       6h10m
server-06             S-06 Bundled leaf-03         6h10m
```

For connections, use:

```console
core@control-1 ~ $ kubectl get connection
NAME                                 TYPE           AGE
leaf-01--mclag-domain--leaf-02       mclag-domain   6h11m
leaf-01--vpc-loopback                vpc-loopback   6h11m
leaf-02--vpc-loopback                vpc-loopback   6h11m
leaf-03--vpc-loopback                vpc-loopback   6h11m
server-01--mclag--leaf-01--leaf-02   mclag          6h11m
server-02--mclag--leaf-01--leaf-02   mclag          6h11m
server-03--unbundled--leaf-01        unbundled      6h11m
server-04--bundled--leaf-02          bundled        6h11m
server-05--unbundled--leaf-03        unbundled      6h11m
server-06--bundled--leaf-03          bundled        6h11m
spine-01--fabric--leaf-01            fabric         6h11m
spine-01--fabric--leaf-02            fabric         6h11m
spine-01--fabric--leaf-03            fabric         6h11m
spine-02--fabric--leaf-01            fabric         6h11m
spine-02--fabric--leaf-02            fabric         6h11m
spine-02--fabric--leaf-03            fabric         6h11m
```

For IPv4 and VLAN namespaces, use:

```console
core@control-1 ~ $ kubectl get ipns
NAME      SUBNETS           AGE
default   ["10.0.0.0/16"]   6h12m

core@control-1 ~ $ kubectl get vlanns
NAME      AGE
default   6h12m
```

## Reset VLAB

If VLAB is currently running, press `Ctrl + C` to stop it. To reset VLAB and start over run `hhfab init -f`. This option forces the process to overwrite your existing configuration in `fab.yaml`.

## Next steps

* [Running Demo](./demo.md)
