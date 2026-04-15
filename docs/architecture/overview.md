# Overview

Hedgehog Open Network Fabric leverages the Kubernetes API to manage its resources. All user-facing APIs are exposed as Kubernetes Custom Resources Definitions (CRDs), allowing users to manage Fabric resources using standard Kubernetes tools.

To make network switches Kubernetes-aware, the Fabric employs an **Agent** running on each switch. This agent acts as an interface  between the Kubernetes control plane and the switch internal network configuration mechanisms. It continuously syncs desired state from Kubernetes via the Fabric Controller and applies configurations using **gNMI** (gRPC Network Management Interface).

Gateway nodes follow the same Kubernetes-native model. The Fabric Controller manages gateway configuration through a dedicated Kubernetes CRD, which the gateway's Dataplane watches directly, continuously reconciling its running state with the desired configuration and reporting observed status back through the Kubernetes API. This keeps gateway management fully consistent with the rest of the Fabric: operators interact exclusively through Kubernetes resources, and operational state is always visible via standard Kubernetes tooling.

## Components

Hedgehog Fabric consists of several key components, distributed between the Control Node and the network devices. The following diagram illustrates these components and their relationships. Hedgehog components have been highlighted in brown color:

``` mermaid
graph TD;
  %% Control Plane
  subgraph Control Node ["Control Node"]
    K[Fabric CLI - kubectl plugin]:::ourComponent
    A[Fabric Controller]:::ourComponent
    P[Fabric Proxy]:::ourComponent
  end

  K -->|Interacts via K8s API| A
  L[Fabricator]:::ourComponent -->|Installs & Configures| A
  A -->|Kubernetes API| SW_AGENT
  SW_AGENT -->|Syncs State| A
  GWD -->|Syncs State| A

  %% Switch
  subgraph Switch
    SW_AGENT[Fabric Agent]:::ourComponent
    SW_ALLOY[Alloy]:::thirdParty
    SW_GNMI[gNMI]:::thirdParty
    SW_CDB[Config DB]:::thirdParty
    SW_ASIC[ASIC]:::thirdParty
    SW_ALLOY -->|scrapes| SW_AGENT
    SW_ALLOY -->|Pushes Logs/Metrics| P
  end

  %% Gateway
  subgraph Gateway
    GWD[Dataplane]:::ourComponent
    GWFA[FRR Agent]:::ourComponent
    GWFRR[FRR]:::thirdParty
    GWA[Alloy]:::thirdParty
    GWD -->|routing config| GWFA
    GWFA -->|config reload| GWFRR
    GWFRR -->|routes & BGP state| GWD
    GWA -->|scrapes /metrics| GWD
    GWA -->|Pushes Logs/Metrics| P
  end

  %% Switch Configuration Flow
  SW_AGENT -->|Applies Config| SW_GNMI
  SW_GNMI -->|Writes/Reads| SW_CDB
  SW_CDB -->|Controls| SW_ASIC

  %% Logs and Metrics Flow
  P -->|Forwards Logs/Metrics| M
  M[LGTM]:::thirdParty

  %% Style definitions for dark mode
  classDef ourComponent fill:#A67C52,stroke:#805D3B,stroke-width:2px,color:#ffffff;
  classDef thirdParty fill:#888888,stroke:#666666,stroke-width:1px,color:#000000;

  %% Add a vertical legend
  subgraph Legend ["Legend"]
    direction RL
    HC[Hedgehog]:::ourComponent
    TPC[Third-Party]:::thirdParty
  end
```

The key components essential for understanding the Fabric architecture are:

### Control Node Components
- **Fabric Controller**: The central control plane component that manages Fabric resources and configurations.
- **Fabric CLI (kubectl plugin)**: A `kubectl` plugin that provides an easy way to manage Fabric resources.
- **Fabric Proxy**: A pod responsible for collecting logs and metrics from switches and gateways (via Alloy) and forwarding them to an external system.
- **Fabricator**: A tool for installing and configuring Fabric, including virtual lab environments.

### Switch Components
- **Fabric Agent**: Runs on each switch and applies configurations received from the control plane.
- **Alloy**: Collects logs and telemetry data from the switch.
- **gNMI Interface**: The main configuration API used by the Fabric Agent to interact with the switch.
- **Config DB**: The central database in SONiC responsible for maintaining switch configuration.
- **ASIC**: The hardware component handling packet forwarding.

The SONiC architecture presented here is a high-level abstraction, for simplicity.

### Gateway Components
- **Dataplane**: A packet processing pipeline that handles NAT, flow tracking, and VXLAN encapsulation/decapsulation. It reads the desired peering and NAT configuration from Kubernetes and generates FRR configuration delivered to the FRR Agent.
- **FRR Agent**: A Hedgehog-written component that receives FRR configuration from the dataplane and applies it to FRR via dynamic reload.
- **FRR (Free Range Routing)**: A suite of routing daemons that provides BGP peering with the fabric switches. FRR advertises VPC peering routes to attract traffic to the gateway, and pushes routes received from the fabric back into the dataplane's forwarding table via the Control Plane Interface (CPI).
- **Alloy**: Collects logs and metrics from the gateway and forwards them to the Fabric Proxy.

Gateway nodes run Flatcar Linux and join the Kubernetes cluster as worker nodes. The Fabric Controller schedules all gateway components onto gateway nodes and delivers configuration through the `GatewayAgent` Kubernetes CRD. The Dataplane watches this CRD directly, keeping its own state synchronized and reporting back observed status. FRR and the FRR Agent are responsible for all routing interactions with the fabric: FRR advertises and receives routes via BGP, while the FRR Agent keeps FRR's configuration in sync with the Dataplane's desired state.

## Architecture Flow

### 1. **Fabric Installation & Configuration**
- The **Fabricator** tool installs and configures Hedgehog Fabric.
- It provisions **Flatcar Linux** for Control Nodes and automatically installs **K3s** (lightweight Kubernetes).
- All components, including their dependencies, are deployed within Kubernetes.

### 2. **Fabric API & Resource Management**
- Hedgehog represents all infrastructure elements as **Fabric resources** using Kubernetes CRDs.
- These CRDs define **switches, servers, control nodes, external systems, and their interconnections**.
- The **Fabric Controller** watches these CRDs and manages configurations accordingly.

### 3. **Switch Configuration & Management**
- The **Fabric Controller** communicates with the **Fabric Agent** on each switch via the Kubernetes API.
- The **Fabric Agent** applies configurations using the **gNMI** interface, updating the **Config DB**.
- The **Config DB** ensures that all settings are applied to the **ASIC** for packet forwarding.

### 4. **Gateway Configuration & Management**
- The **Fabric Controller** publishes a `GatewayAgent` CRD containing the desired gateway configuration: BGP settings, VPC peerings, NAT rules, and gateway group membership.
- The **Dataplane** watches the `GatewayAgent` CRD via the Kubernetes API, applies the configuration, and writes its observed state (including FRR applied generation and per-VPC traffic statistics) back to the CRD status.
- The **Dataplane** generates FRR configuration from the desired state and delivers it to the **FRR Agent**, which applies it to FRR via dynamic reload.
- **FRR** establishes BGP sessions with the fabric switches to advertise VPC peering routes. It pushes received routes and BGP state back to the **Dataplane** via the Control Plane Interface (CPI) and BGP Monitoring Protocol (BMP) respectively.

### 5. **Telemetry & Monitoring**
- The **Alloy** agent on switches and gateways collects logs and metrics.
- Logs and metrics are sent to the **Fabric Proxy** running in Kubernetes.
- The **Fabric Proxy** forwards this data to **LGTM**, an external logging and monitoring system.
