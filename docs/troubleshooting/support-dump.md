# Support Dump

A support dump is a single file with the state of the Fabric control plane: the API objects, the logs of all pods and
the state of the gateways. It's the first thing to collect when reporting an issue, as it captures the state of the
Fabric at that point in time.

## Creating a Support Dump

Run on the control node:

```console
core@control-1 ~ $ kubectl hhfab support dump --yes
```

The dump is written into the current directory as `hhfab-<timestamp>.hhs`, e.g. `hhfab-2026-11-04T10-33-17-08-00.hhs`.
It's compressed and usually takes from a few to tens of MB, and collecting it is limited to 15 minutes.

!!! warning
    Credentials are redacted from the dump (see [Redacted Data](#redacted-data)), but it still contains the full
    configuration of the Fabric, e.g. IP addresses, names and logs. Only share it with people you trust, e.g. the
    Hedgehog support team.

`kubectl hhfab support dump` options:

- `--yes` (`-y`): confirm that the dump may contain sensitive data, required
- `--name` (`-n`): name of the dump, the file is `<name>.hhs`, `hhfab-<timestamp>` by default
- `--workdir` (`-w`): directory to write the dump into, the current directory by default
- `--force` (`-f`): overwrite an existing dump with the same name

To copy the dump from the control node, e.g. with `scp`, use the path it was written to; for a dump created in the
home directory of the `core` user:

```bash
scp core@<control node IP>:hhfab-2026-11-04T10-33-17-08-00.hhs .
```

## What's Included

- **Metadata**: the name of the dump, when and by whom it was created (hostname, user, OS and `kubectl hhfab` version)
- **API objects**: all objects of the Fabric API (Switches, Connections, VPCs, Externals, Gateways, Agents, etc.), of the
  Fabricator API (Fabricator, ControlNodes, FabNodes) and of the fabric controller internal APIs, as well as the
  Kubernetes objects the Fabric runs on: nodes, pods, deployments and other workloads, jobs, services, events, leases,
  certificates, Helm charts, RBAC, webhooks and storage
- **Pod logs**: the current and, if the container restarted, the previous logs of every container of all pods, including
  the fabric controller, the DHCP server, the boot server and the gateway dataplanes
- **Gateway insights**: the output of commands run in the dataplane container of every gateway:
    - `show tech` of the dataplane CLI, which includes everything it shows, e.g. the link state, transceivers and LLDP
      neighbors
    - FRR commands: `show daemons`, `show hedgehog rpc stats`, `show zebra client summary`, `show running-config`,
      `show interface brief`, `show bfd peers`, `show bgp summary`, `show ip route vrf all` and `show ip fib vrf all`

The dump doesn't include anything collected from the switches directly, but their state reported by the agents is
included in the Agent objects.

### Redacted Data

The following data is replaced with `SUPPORT-DUMP-REDACTED`:

- the data of all Secrets and ConfigMaps
- the values of Helm charts
- passwords, password hashes, SSH keys and tokens wherever they show up in the objects, e.g. the users of the control
  node and the switches, the registry credentials and the credentials of the observability targets
- the `kubectl.kubernetes.io/last-applied-configuration` annotation, which holds a copy of the object

## Extracting a Support Dump

A support dump can be extracted into a tree of files to browse and search it with the usual tools. On the control
node:

```console
core@control-1 ~ $ kubectl hhfab support extract hhfab-2026-11-04T10-33-17-08-00.hhs
```

or anywhere else with `hhfab`:

```console
$ hhfab support extract hhfab-2026-11-04T10-33-17-08-00.hhs
```

It's extracted into a directory named after the dump without `.hhs`, e.g. `hhfab-2026-11-04T10-33-17-08-00/`, which
must not exist yet. Options:

- `--output` (`-o`): directory to extract into instead
- `--strip-colors`: strip the color codes from the pod logs and gateway insights, enabled by default, use
  `--strip-colors=false` to keep them
- `--ascii`: replace the box drawing and other decorations in the pod logs and gateway insights with ASCII

The extracted dump has the following structure:

```
hhfab-2026-11-04T10-33-17-08-00/
├── support.yaml
├── resources/
│   ├── githedgehog.com/
│   │   ├── v1beta1.wiring.githedgehog.com.Switch/default/leaf-01.yaml
│   │   ├── v1beta1.vpc.githedgehog.com.VPC/default/vpc-01.yaml
│   │   └── ...
│   └── k8s.io/
│       ├── v1.Pod/fab/fabric-ctrl-6d4f9c7b8-x2xkq.yaml
│       └── ...
├── podlogs/
│   └── fab/
│       ├── fabric-ctrl-6d4f9c7b8-x2xkq/manager.current.log
│       └── ...
└── insights/
    └── gateway-1/
        ├── dataplane-show-tech.stdout.txt
        ├── frr-show-bgp-summary.stdout.txt
        └── ...
```

- `support.yaml`: the dump metadata and a summary of what it has, e.g. the number of objects per kind
- `resources/<domain>/<version>[.<group>].<Kind>/[<namespace>/]<name>.yaml`: every object, grouped by the domain of its
  API group, `githedgehog.com` for the Fabric objects and `k8s.io` for the Kubernetes ones
- `podlogs/<namespace>/<pod>/<container>.{current,previous}.log`: the current and the previous logs of every container
- `insights/<gateway>/<command>.{stdout,stderr,error}.txt`: the output of every command run on the gateways, with
  `error` set if the command couldn't be run, e.g. because the gateway pod wasn't running

Only the files with any content are written, e.g. there is no `previous.log` for a container that didn't restart.
