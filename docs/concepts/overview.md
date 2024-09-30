# Concepts

## Introduction

Hedgehog Open Network Fabric is built on top of Kubernetes and uses Kubernetes API to manage its resources. It means
that all user-facing APIs are [Kubernetes Custom Resources (CRDs)][CRDs], so you can use standard Kubernetes tools to
manage Fabric resources.

[CRDs]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/

Hedgehog Fabric consists of the following components:

* Fabricator - special tool to install and configure Fabric, or to run virtual labs
* Control Node - one or more Kubernetes nodes in a single cluster running Fabric software:
    * Das Boot - set of services providing switch boot and installation
    * Fabric Controller - main control plane component that manages Fabric resources
* Fabric Kubectl plugin (Fabric CLI) - kubectl plugin to manage Fabric resources in an easy way
* Fabric Agent - runs on every switch and manages switch configuration

## Fabric API

All infrastructure is represented as a set of Fabric resource (Kubernetes CRDs) and named Wiring Diagram. With this
representation, Fabric defines switches, servers, control nodes, external systems and connections between them in a
single place and then uses these definitions to deploy and manage the whole infrastructure. On top of the Wiring
Diagram, Fabric provides a set of APIs to manage the VPCs and the connections between them and between VPCs and External
systems.

### Wiring Diagram API

Wiring Diagram consists of the following resources:

* "Devices": describe *any* device in the Fabric and can be of two types:
    * __Switch__: configuration of the switch, containing for example: port group speeds, port breakouts, switch IP/ASN
    * __Server__: *any* physical server attached to the Fabric including Control Nodes
* __Connection__: *any* logical connection for devices
    * usually it's a connection between two or more ports on two different devices
    * for example: MCLAG Peer Link, Unbundled/MCLAG server connections, Fabric connection between spine and leaf
* __VLANNamespace__ -> non-overlapping VLAN ranges for attaching servers
* __IPv4Namespace__ -> non-overlapping IPv4 ranges for VPC subnets

### User-facing API

* VPC API
    * __VPC__: Virtual Private Cloud, similar to a public cloud VPC, provides an isolated private network for the
      resources, with support for multiple subnets, each with user-defined VLANs and optional DHCP service
    * __VPCAttachment__: represents a specific VPC subnet assignment to the Connection object which means exact server port to a VPC binding
    * __VPCPeering__: enables VPC-to-VPC connectivity (could be Local where VPCs are used or Remote peering on the border/mixed leaves)
* External API
    * __External__: definition of the "external system" to peer with (could be one or multiple devices such as edge/provider routers)
    * __ExternalAttachment__: configuration for a specific switch (using Connection object) describing how it connects to an external system
    * __ExternalPeering__: provides VPC with External connectivity by exposing specific VPC subnets to the external system and allowing inbound routes from it

## Fabricator

Installer builder and VLAB.

* Installer builder based on a preset (currently: `vlab` for virtual and `lab` for physical)
    * Main input: Wiring Diagram
    * All input artifacts coming from OCI registry
    * Always full airgap (everything running from private registry)
    * Flatcar Linux for Control Node, generated `ignition.json`
    * Automatic K3s installation and private registry setup
    * All components and their dependencies running in Kubernetes
* Integrated Virtual Lab (VLAB) management
* Future:
    * In-cluster (control) Operator to manage all components
    * Upgrades handling for everything starting Control Node OS
    * Installation progress, status and retries
    * Disaster recovery and backups

## Das Boot

Switch boot and installation.

* Seeder
    * Actual switch provisioning
    * ONIE on a switch discovers Control Node using LLDP
    * Loads and runs Hedgehog's multi-stage installer
        * Network configuration and identity setup
        * Performs device registration
        * Hedgehog identity partition gets created on the switch
        * Downloads SONiC installer and runs it
        * Downloads Agent and its config and installs to the switch
* Registration Controller
    * Device identity and registration
* Actual SONiC installers
* Miscellaneous: rsyslog/ntp

## Fabric

Control plane and switch agent.

* Currently Fabric is basically a single controller manager running in Kubernetes
    * It includes controllers for different CRDs and needs
    * For example, auto assigning VNIs to VPCs or generating the Agent configuration
    * Additionally, it's running the admission webhook for Hedgehog's CRD APIs
* The Agent is watching for the corresponding Agent CRD in Kubernetes API
    * It applies the changes and saves the new configuration locally
    * It reports status and information back to the API
    * It can perform reinstallation and reboot of SONiC
