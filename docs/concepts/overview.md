# Concepts

## Introduction

Hedgehog Open Network Fabric is build on top of Kubernetes and uses Kubernetes API to manage its resources. It means
that all user-facing APIs are [Kubernetes Custom Resources (CRDs)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
and so you can use standard Kubernetes tools to manage Fabric resources.

Hedgehog Fabric consists of the following components:

* Fabricator - special tool that allows to install and configure Fabric as well as run virtual labs
* Control Node - one or more Kubernetes nodes in a single clusters running Fabric software
    * Das Boot - set of services providing switch boot and installation
    * Fabric Controller - main control plane component that manages Fabric resources
* Fabric Kubectl plugin (Fabric CLI) - plugin for kubectl that allows to manage Fabric resources in an easy way
* Fabric Agent - runs on every switch and manages switch configuration

## Fabric API

All infrastructure is represented as a set of Fabric resource (Kubernetes CRDs) and named Wiring Diagram. It allows to
define switches, servers, control nodes, external systems and connections between them in a single place and then use
it to deploy and manage the whole infrastructure. On top of it Fabric provides a set of APIs to manage the VPCs and
connections between them and between VPCs and External systems.

### Wiring Diagram API

Wiring Diagram consists of the following resources:

* "Devices": describes any device in the Fabric
    * __Switch__: configuration of the switch, like port group speeds, port breakouts, switch IP/ASN, etc.
    * __Server__: any physical server attached to the Fabric including control nodes
* __Connection__: *any* logical connection for devices
    * usually it's a connection between two or more ports on two different devices
    * incl. MCLAG Peer Link, Unbundled/MCLAG server connections, Fabric connection between spine and leaf etc.
* __VLANNamespace__ -> non-overlapping VLAN ranges for attaching servers
* __IPv4Namespace__ -> non-overlapping IPv4 ranges for VPC subnets

### User-facing API

* VPC API
    * __VPC__: Virtual Private Cloud, similar to the public cloud VPC it provides an isolated private network for the
      resources with support for multiple subnets each with user-provided VLANs and on-demand DHCP
    * __VPCAttachment__: represents a specific VPC subnet assignment to the Connection object which means exact server port to a VPC binding
    * __VPCPeering__: enables VPC to VPC connectivity (could be Local where VPCs are used or Remote peering on the border/mixed leafs)
* External API
    * __External__: definition of the "external system" to peer with (could be one or multiple devices such as edge/provider routers)
    * __ExternalAttachment__: configuration for a specific switch (using Connection object) describing how it connects to an external system
    * __ExternalPeering__: enables VPC to External connectivity by exposing specific VPC subnets to the external system and allowing inbound routes from it

## Fabricator

Installer builder and VLAB.

* Installer builder based on a preset (currently vlab for virtual & lab for physical)
    * Main input - wiring diagram
    * All input artifacts coming from OCI registry
    * Always full airgap (everything running from private registry)
    * Flatcar Linux for control node, generated ignition.json
    * Automatic k3s installation and private registry setup
    * All components and their dependencies running in K8s
* Integrated Virtual Lab (VLAB) management
* Future:
    * In-cluster (control) Operator to manage all components
    * Upgrades handling for everything starting control node OS
    * Installation progress, status and retries
    * Disaster recovery and backups

## Das Boot

Switch boot and installation.

* Seeder
    * Actual switch provisioning
    * ONIE on a switch discovers control node using LLDP
    * It loads and runs our multi-stage installer
        * Network configuration & identity setup
        * Performs device registration
        * Hedgehog identity partition gets created on the switch
        * Downloads SONiC installer and runs it
        * Downloads Agent and it's config and installs to the switch
* Registration Controller
    * Device identity and registration
* Actual SONiC installers
* Misc: rsyslog/ntp

## Fabric

Control plane and switch agent.

* Currently Fabric is basically single controller manager running in K8s
    * It includes controllers for different CRDs and needs
    * For example, auto assigning VNIs to VPC or generating Agent config
    * Additionally, it's running admission webhook for our CRD APIs
* Agent is watching for the corresponding Agent CRD in K8s API
    * It applies the changes and saves new config locally
    * It reports back some status and information back to API
    * Can perform reinstall and reboot of SONiC
