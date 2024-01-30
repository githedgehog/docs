# Running VLAB

Please, make sure to follow prerequisites and check system requirements in the [VLAB Overview](overview.md) section
before running VLAB.

## Initialize VLAB

As a first step you need to initialize Fabricator for the VLAB by running `hhfab init --preset vlab` (or `-p vlab`). It
supports a lot of customization options which you can find by adding `--help` to the command. If you want to tune the
topology used for the VLAB you can use `--fabric-mode` (or `-m`) flag to choose between `spine-leaf` (default) and
`collapsed-core` topologies as well as you can configure the number of spines, leafs, connections and etc. For example,
`--spines-count` and `--mclag-leafs-count` flags allows to set number of spines and MCLAG leafs respectively.

So, by default you'll get 2 spines, 2 MCLAG leafs and 1 non-MCLAG leaf with 2 fabric connections (between each spine and
leaf), 2 MCLAG peer links and 2 MCLAG session links as well as 2 loopbacks per leaf for implementing VPC Loopback
workaround.

```bash
ubuntu@docs:~$ hhfab init -p vlab
01:17:44 INF Generating wiring from gen flags
01:17:44 INF Building wiring diagram fabricMode=spine-leaf chainControlLink=false controlLinksCount=0
01:17:44 INF                     >>> spinesCount=2 fabricLinksCount=2
01:17:44 INF                     >>> mclagLeafsCount=2 orphanLeafsCount=1
01:17:44 INF                     >>> mclagSessionLinks=2 mclagPeerLinks=2
01:17:44 INF                     >>> vpcLoopbacks=2
01:17:44 WRN Wiring is not hydrated, hydrating reason="error validating wiring: ASN not set for switch leaf-01"
01:17:44 INF Initialized preset=vlab fabricMode=spine-leaf config=.hhfab/config.yaml wiring=.hhfab/wiring.yaml
```

Or if you want to run Collapsed Core topology with 2 MCLAG switches:

```bash
ubuntu@docs:~$ hhfab init -p vlab -m collapsed-core
01:20:07 INF Generating wiring from gen flags
01:20:07 INF Building wiring diagram fabricMode=collapsed-core chainControlLink=false controlLinksCount=0
01:20:07 INF                     >>> mclagLeafsCount=2 orphanLeafsCount=0
01:20:07 INF                     >>> mclagSessionLinks=2 mclagPeerLinks=2
01:20:07 INF                     >>> vpcLoopbacks=2
01:20:07 WRN Wiring is not hydrated, hydrating reason="error validating wiring: ASN not set for switch leaf-01"
01:20:07 INF Initialized preset=vlab fabricMode=collapsed-core config=.hhfab/config.yaml wiring=.hhfab/wiring.yaml
```

Or you can run custom topology with 2 spines, 4 MCLAG leafs and 2 non-MCLAG leafs using flags:

```bash
ubuntu@docs:~$ hhfab init -p vlab --mclag-leafs-count 4 --orphan-leafs-count 2
01:21:53 INF Generating wiring from gen flags
01:21:53 INF Building wiring diagram fabricMode=spine-leaf chainControlLink=false controlLinksCount=0
01:21:53 INF                     >>> spinesCount=2 fabricLinksCount=2
01:21:53 INF                     >>> mclagLeafsCount=4 orphanLeafsCount=2
01:21:53 INF                     >>> mclagSessionLinks=2 mclagPeerLinks=2
01:21:53 INF                     >>> vpcLoopbacks=2
01:21:53 WRN Wiring is not hydrated, hydrating reason="error validating wiring: ASN not set for switch leaf-01"
01:21:53 INF Initialized preset=vlab fabricMode=spine-leaf config=.hhfab/config.yaml wiring=.hhfab/wiring.yaml
```

Additionally, you can do extra Fabric configuration using flags on `init` command or by passing config file, more
information about it is available in the [Fabric Configuration](../install-upgrade/config.md) section.

Once you have initialized the VLAB you need to download all artifacts and build the installer using `hhfab build`
command. It will automatically download all required artifacts from the OCI registry and build the installer as well as
all other prerequisites for running the VLAB.

## Build the installer and VLAB

```bash
ubuntu@docs:~$ hhfab build
01:23:33 INF Building component=base
01:23:33 WRN Attention! Development mode enabled - this is not secure! Default users and keys will be created.
...
01:23:33 INF Building component=control-os
01:23:33 INF Building component=k3s
01:23:33 INF Downloading name=m.l.hhdev.io:31000/githedgehog/k3s:v1.27.4-k3s1 to=.hhfab/control-install
Copying k3s-airgap-images-amd64.tar.gz  187.36 MiB / 187.36 MiB   ⠙   0.00 b/s done
Copying k3s                               56.50 MiB / 56.50 MiB   ⠙   0.00 b/s done
01:23:35 INF Building component=zot
01:23:35 INF Downloading name=m.l.hhdev.io:31000/githedgehog/zot:v1.4.3 to=.hhfab/control-install
Copying zot-airgap-images-amd64.tar.gz  19.24 MiB / 19.24 MiB   ⠸   0.00 b/s done
01:23:35 INF Building component=misc
01:23:35 INF Downloading name=m.l.hhdev.io:31000/githedgehog/fabricator/k9s:v0.27.4 to=.hhfab/control-install
Copying k9s  57.75 MiB / 57.75 MiB   ⠼   0.00 b/s done
...
01:25:40 INF Planned bundle=control-install name=fabric-api-chart op="push fabric/charts/fabric-api:v0.23.0"
01:25:40 INF Planned bundle=control-install name=fabric-image op="push fabric/fabric:v0.23.0"
01:25:40 INF Planned bundle=control-install name=fabric-chart op="push fabric/charts/fabric:v0.23.0"
01:25:40 INF Planned bundle=control-install name=fabric-agent-seeder op="push fabric/agent/x86_64:latest"
01:25:40 INF Planned bundle=control-install name=fabric-agent op="push fabric/agent:v0.23.0"
...
01:25:40 INF Recipe created bundle=control-install actions=67
01:25:40 INF Creating recipe bundle=server-install
01:25:40 INF Planned bundle=server-install name=toolbox op="file /opt/hedgehog/toolbox.tar"
01:25:40 INF Planned bundle=server-install name=toolbox-load op="exec ctr"
01:25:40 INF Planned bundle=server-install name=hhnet op="file /opt/bin/hhnet"
01:25:40 INF Recipe created bundle=server-install actions=3
01:25:40 INF Building done took=2m6.813384532s
01:25:40 INF Packing bundle=control-install target=control-install.tgz
01:25:45 INF Packing bundle=server-install target=server-install.tgz
01:25:45 INF Packing done took=5.67007384s
```

As soon as it's done you can run the VLAB using `hhfab vlab up` command. It will automatically start all VMs and run
the installers on the control node and test servers. It will take some time for all VMs to come up and for the installer
to finish, you will see the progress in the output. If you stop the command, it'll stop all VMs, and you can re-run it
to get VMs back up and running.

## Run VMs and installers

```bash
ubuntu@docs:~$ hhfab vlab up
01:29:13 INF Starting VLAB server... basedir=.hhfab/vlab-vms vm-size="" dry-run=false
01:29:13 INF VM id=0 name=control-1 type=control
01:29:13 INF VM id=1 name=server-01 type=server
01:29:13 INF VM id=2 name=server-02 type=server
01:29:13 INF VM id=3 name=server-03 type=server
01:29:13 INF VM id=4 name=server-04 type=server
01:29:13 INF VM id=5 name=server-05 type=server
01:29:13 INF VM id=6 name=server-06 type=server
01:29:13 INF VM id=7 name=leaf-01 type=switch-vs
01:29:13 INF VM id=8 name=leaf-02 type=switch-vs
01:29:13 INF VM id=9 name=leaf-03 type=switch-vs
01:29:13 INF VM id=10 name=spine-01 type=switch-vs
01:29:13 INF VM id=11 name=spine-02 type=switch-vs
01:29:13 INF Total VM resources cpu="38 vCPUs" ram="36352 MB" disk="410 GB"
...
01:29:13 INF Preparing VM id=0 name=control-1 type=control
01:29:13 INF Copying files  from=.hhfab/control-os/ignition.json to=.hhfab/vlab-vms/control-1/ignition.json
01:29:13 INF Copying files  from=.hhfab/vlab-files/flatcar.img to=.hhfab/vlab-vms/control-1/os.img
 947.56 MiB / 947.56 MiB [==========================================================] 5.13 GiB/s done
01:29:14 INF Copying files  from=.hhfab/vlab-files/flatcar_efi_code.fd to=.hhfab/vlab-vms/control-1/efi_code.fd
01:29:14 INF Copying files  from=.hhfab/vlab-files/flatcar_efi_vars.fd to=.hhfab/vlab-vms/control-1/efi_vars.fd
01:29:14 INF Resizing VM image (may require sudo password) name=control-1
01:29:17 INF Initializing TPM name=control-1
...
01:29:46 INF Installing VM name=control-1 type=control
01:29:46 INF Installing VM name=server-01 type=server
01:29:46 INF Installing VM name=server-02 type=server
01:29:46 INF Installing VM name=server-03 type=server
01:29:47 INF Installing VM name=server-04 type=server
01:29:47 INF Installing VM name=server-05 type=server
01:29:47 INF Installing VM name=server-06 type=server
01:29:49 INF Running VM id=0 name=control-1 type=control
01:29:49 INF Running VM id=1 name=server-01 type=server
01:29:49 INF Running VM id=2 name=server-02 type=server
01:29:49 INF Running VM id=3 name=server-03 type=server
01:29:50 INF Running VM id=4 name=server-04 type=server
01:29:50 INF Running VM id=5 name=server-05 type=server
01:29:50 INF Running VM id=6 name=server-06 type=server
01:29:50 INF Running VM id=7 name=leaf-01 type=switch-vs
01:29:50 INF Running VM id=8 name=leaf-02 type=switch-vs
01:29:51 INF Running VM id=9 name=leaf-03 type=switch-vs
01:29:51 INF Running VM id=10 name=spine-01 type=switch-vs
01:29:51 INF Running VM id=11 name=spine-02 type=switch-vs
...
01:30:41 INF VM installed name=server-06 type=server installer=server-install
01:30:41 INF VM installed name=server-01 type=server installer=server-install
01:30:41 INF VM installed name=server-02 type=server installer=server-install
01:30:41 INF VM installed name=server-04 type=server installer=server-install
01:30:41 INF VM installed name=server-03 type=server installer=server-install
01:30:41 INF VM installed name=server-05 type=server installer=server-install
...
01:31:04 INF Running installer on VM name=control-1 type=control installer=control-install
...
01:35:15 INF Done took=3m39.586394608s
01:35:15 INF VM installed name=control-1 type=control installer=control-install
```

After you see `VM installed name=control-1`, it means that the installer has finished and you can get into the control
node and other VMs to watch the Fabric coming up and switches getting provisioned.

## Configuring VLAB VMs

By default, all test server VMs are isolated and have no connectivity to the host or internet. You can configure it
using `hhfab vlab up --restrict-servers=false` flag to allow the test servers to access the internet and the host. It
will mean that VMs will have default route pointing to the host which means in case of the VPC peering you'll need to
configure test server VMs to use the VPC attachement as a default route (or just some specific subnets).

Additionally, you can configure the size of all VMs using `hhfab vlab up --vm-size <size>` flag. It will allow you to
choose from one of the presets (compact, default, full and huge) to get the control, switch and server VMs of different
sizes.

## Default credentials

Fabricator will create default users and keys for you to login into the control node and test servers as well as for the
SONiC Virtual Switches.

Default user with passwordless sudo for the control node and test servers is `core` with password `HHFab.Admin!`.
Admin user with full access and passwordless sudo for the switches is `admin` with password `HHFab.Admin!`.
Read-only, non-sudo user with access only to the switch CLI for the switches is `op` with password `HHFab.Op!`.

## Accessing the VLAB

The `hhfab vlab` command provides `ssh` and `serial` subcommands to access the VMs. You can use `ssh` to get into the
control node and test servers after the VMs are started. You can use `serial` to get into the switch VMs while they are
provisioning and installing the software. After switches are installed you can use `ssh` to get into them.

You can select device you want to access or pass the name using the `--vm` flag.

```bash
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

On the control node you'll have access to the kubectl, Fabric CLI and k9s to manage the Fabric. You can find information
about the switches provisioning by running `kubectl get agents -o wide`. It usually takes about 10-15 minutes for the
switches to get installed.

After switches are provisioned you will see something like this:

```bash
core@control-1 ~ $ kubectl get agents -o wide
NAME       ROLE          DESCR           HWSKU                      ASIC   HEARTBEAT   APPLIED   APPLIEDG   CURRENTG   VERSION   SOFTWARE                ATTEMPT   ATTEMPTG   AGE
leaf-01    server-leaf   VS-01 MCLAG 1   DellEMC-S5248f-P-25G-DPB   vs     30s         5m5s      4          4          v0.23.0   4.1.1-Enterprise_Base   5m5s      4          10m
leaf-02    server-leaf   VS-02 MCLAG 1   DellEMC-S5248f-P-25G-DPB   vs     27s         3m30s     3          3          v0.23.0   4.1.1-Enterprise_Base   3m30s     3          10m
leaf-03    server-leaf   VS-03           DellEMC-S5248f-P-25G-DPB   vs     18s         3m52s     4          4          v0.23.0   4.1.1-Enterprise_Base   3m52s     4          10m
spine-01   spine         VS-04           DellEMC-S5248f-P-25G-DPB   vs     26s         3m59s     3          3          v0.23.0   4.1.1-Enterprise_Base   3m59s     3          10m
spine-02   spine         VS-05           DellEMC-S5248f-P-25G-DPB   vs     19s         3m53s     4          4          v0.23.0   4.1.1-Enterprise_Base   3m53s     4          10m
```

`Heartbeat` column shows how long ago the switch has sent the heartbeat to the control node. `Applied` column shows how long
ago the switch has applied the configuration. `AppliedG` shows the generation of the configuration applied. `CurrentG` shows
the generation of the configuration the switch is supposed to run. If `AppliedG` and `CurrentG` are different it means that
the switch is in the process of applying the configuration.

At that point Fabric is ready and you can use `kubectl` and `kubectl fabric` to manage the Fabric. You can find more
about it in the [Running Demo](demo.md) and [User Guide](../user-guide/overview.md) sections.

## Getting main Fabric objects

You can get the main Fabric objects using `kubectl get` command on the control node. You can find more details about
using the Fabric in the [User Guide](../user-guide/overview.md), [Fabric API](../reference/api.md) and
[Fabric CLI](../reference/cli.md) sections.

 For example, to get the list of switches you can run:

```bash
core@control-1 ~ $ kubectl get switch
NAME       ROLE          DESCR           GROUPS   LOCATIONUUID                           AGE
leaf-01    server-leaf   VS-01 MCLAG 1            5e2ae08a-8ba9-599a-ae0f-58c17cbbac67   6h10m
leaf-02    server-leaf   VS-02 MCLAG 1            5a310b84-153e-5e1c-ae99-dff9bf1bfc91   6h10m
leaf-03    server-leaf   VS-03                    5f5f4ad5-c300-5ae3-9e47-f7898a087969   6h10m
spine-01   spine         VS-04                    3e2c4992-a2e4-594b-bbd1-f8b2fd9c13da   6h10m
spine-02   spine         VS-05                    96fbd4eb-53b5-5a4c-8d6a-bbc27d883030   6h10m
```

Similar for the servers:

```bash
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

For connections:

```bash
core@control-1 ~ $ kubectl get connection
NAME                                 TYPE           AGE
control-1--mgmt--leaf-01             management     6h11m
control-1--mgmt--leaf-02             management     6h11m
control-1--mgmt--leaf-03             management     6h11m
control-1--mgmt--spine-01            management     6h11m
control-1--mgmt--spine-02            management     6h11m
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

For IPv4 and VLAN namespaces:

```bash
core@control-1 ~ $ kubectl get ipns
NAME      SUBNETS           AGE
default   ["10.0.0.0/16"]   6h12m

core@control-1 ~ $ kubectl get vlanns
NAME      AGE
default   6h12m
```

## Reset VLAB

To reset VLAB and start over just remove the `.hhfab` directory and run `hhfab init` again.

## Next steps

* [Running Demo](./demo.md)
