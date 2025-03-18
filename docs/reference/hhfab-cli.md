
# Fabricator CLI Reference

The `hhfab` CLI is the Hedgehog Fabricator command-line tool for building, installing, and managing Hedgehog Fabric environments.

## Usage

```bash
hhfab [global options] command [command options]
```

## Version

Check the version with:

```bash
hhfab --version
```

## Commands and Options

| Command | Subcommand | Options | Description |
|---------|------------|---------|-------------|
| **init** | — | `--registry-repo`, `--registry-prefix`, `--config`, `--force`, `--wiring`, `--fabric-mode`, `--tls-san`, `--default-authorized-keys`, `--default-password-hash`, `--dev`, `--include-onie`, `--import-host-upstream`, `--control-node-mgmt-link`, `--gateway` | Initialize working directory and create `fab.yaml` and other files. |
| **validate** | — | `--hydrate-mode` *(default: "if-not-present")* | Validate configuration and wiring files. |
| **diagram** | — | `--format` *(default: "drawio")*, `--style` *(default: "hedgehog")* | Generate network topology diagrams. |
| **versions** | — | — | Print versions of all components. |
| **build** | — | `--mode` *(default: "iso")* | Build installers. |
| **vlab** | generate | `--spines-count`, `--fabric-links-count`, `--mclag-leafs-count`, `--eslag-leaf-groups`, `--orphan-leafs-count`, `--mclag-session-links`, `--mclag-peer-links`, `--vpc-loopbacks`, `--mclag-servers`, `--eslag-servers`, `--unbundled-servers`, `--bundled-servers`, `--no-switches`, `--gateway-uplinks` *(default: 2)* | Generate VLAB wiring diagram. |
|  | up | `--recreate`, `--kill-stale` *(default: true)*, `--controls-restricted` *(default: true)*, `--servers-restricted` *(default: true)*, `--build-mode` *(default: "iso")*, `--control-upgrade`, `--fail-fast` *(default: true)*, `--ready`, `--collect-show-tech` | Start the Virtual Lab environment. |
|  | ssh | `--name` | SSH to a VLAB VM or hardware. |
|  | serial | `--name` | Get serial console of a VLAB VM or hardware. |
|  | seriallog | `--name` | Get serial console log of a VLAB VM or hardware. |
|  | show-tech | — | Collect diagnostic information from all VLAB devices. |
|  | setup-vpcs | `--wait-switches-ready` *(default: true)*, `--force-cleanup`, `--vlanns` *(default: "default")*, `--ipns` *(default: "default")*, `--servers-per-subnet` *(default: 1)*, `--subnets-per-vpc` *(default: 1)*, `--dns-servers`, `--time-servers`, `--interface-mtu` | Setup VPCs and VPCAttachments. |
|  | setup-peerings | `--wait-switches-ready` *(default: true)* | Setup VPC and external peerings. |
|  | test-connectivity | `--wait-switches-ready` *(default: true)*, `--pings` *(default: 5)*, `--iperfs` *(default: 10)*, `--iperfs-speed` *(default: 8500)*, `--curls` *(default: 3)*, `--source`, `--destination` | Test connectivity between servers. |
|  | wait-switches | — | Wait for switches to be ready. |
|  | inspect-switches | `--wait-applied-for` *(default: 120)*, `--strict` *(default: true)* | Wait for readiness and inspect switches. |
| **switch** | reinstall | `--name`, `--mode` *(default: "hard-reset")*, `--wait-ready`, `--switch-username`, `--switch-password`, `--pdu-username`, `--pdu-password` | Reboot/reset and reinstall NOS on switches. |
|  | power | `--name`, `--action` *(default: "cycle")*, `--pdu-username`, `--pdu-password` | Manage switch power state using the PDU. |
| **_helpers** | setup-taps | `--count` *(max: 100)* | Setup tap devices and a bridge for VLAB. |
|  | vfio-pci-bind | — | Bind devices to vfio-pci driver for passthrough. |
|  | kill-stale-vms | — | Kill stale VLAB VMs. |

## Command Details

### `init`
Initializes working directory and configuration files.

**Usage:**
```bash
hhfab init [options]
```

**Options:**

- `--registry-repo` – Download artifacts from specific registry repository.
- `--registry-prefix` – Prepend artifact names with specific prefix.
- `--config` – Use existing config file.
- `--force` – Overwrite existing files.
- `--wiring` – Include wiring diagram file.
- `--fabric-mode` *(default: "spine-leaf")* – Set fabric mode.
- `--tls-san` – IPs and DNS names used to access the API.
- `--default-authorized-keys` – Default authorized keys.
- `--default-password-hash` – Default password hash.
- `--dev` – Use default dev credentials (unsafe).
- `--include-onie` – Include ONIE updaters for supported switches.
- `--import-host-upstream` – Import host repo/prefix as an upstream registry mode.
- `--control-node-mgmt-link` – Control node management link.
- `--gateway` – Add and enable gateway node.

---

### `validate`
Validates the configuration and wiring files.

**Usage:**
```bash
hhfab validate [options]
```

**Options:**

- `--hydrate-mode` *(default: "if-not-present")* – Set hydrate mode.

---

### `diagram`
Generate network topology diagrams.

**Usage:**
```bash
hhfab diagram [options]
```

**Options:**

- `--format` *(default: "drawio")* – Diagram format.
- `--style` *(default: "hedgehog")* – Diagram style.

---

### `versions`
Print versions of all components.

**Usage:**
```bash
hhfab versions
```

---

### `build`
Build Hedgehog installer.

**Usage:**
```bash
hhfab build [options]
```

**Options:**

- `--mode` *(default: "iso")* – Build mode (iso, qcow2, raw).

---

### `switch reinstall`
Reinstall the OS on switches.

**Usage:**
```bash
hhfab switch reinstall [options]
```

**Options:**

- `--name` – Switch name.
- `--mode` *(default: "hard-reset")* – Restart mode.
- `--wait-ready` – Wait until switch is ready.
- `--switch-username` – Switch username for reboot mode.
- `--switch-password` – Switch password for reboot mode.

---

## Global Options
- `--workdir` – Specify working directory.
- `--cache-dir` – Specify cache directory.
- `--verbose`, `-v` – Verbose output (includes debug).
- `--brief`, `-b` – Brief output (only warnings and errors).
- `--yes`, `-y` – Assume "yes" for potentially dangerous operations.

