# Overview

Hedgehog Open Network Fabric leverages the Kubernetes API to manage its resources. All user-facing APIs are exposed as Kubernetes Custom Resources Definitions (CRDs), allowing users to manage Fabric resources using standard Kubernetes tools.

To make network switches Kubernetes-aware, the Fabric employs an **Agent** running on each switch. This agent acts as an interface  between the Kubernetes control plane and the switch internal network configuration mechanisms. It continuously syncs desired state from Kubernetes via the Fabric Controller and applies configurations using **gNMI** (gRPC Network Management Interface).

## Components

Hedgehog Fabric consists of several key components, distributed between the Control Node and the Network devices. The following diagram breaks down the components of a [mesh topology](fabric.md#mesh). Hedgehog components have been highlighted in brown color:

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
  A -->|Kubernetes API| B1
  B1 -->|Syncs State| A;
  A -->|Kubernetes API| B2
  B2 -->|Syncs State| A;

  %% Mesh - Two Switches
  subgraph SONiC Leaf 2
    B1[Fabric Agent]:::ourComponent -->|Scraped by| C1[Alloy]:::thirdParty
    C1 -->|Pushes Logs/Metrics| P
    D1[gNMI]:::thirdParty
    E1[Config DB]:::thirdParty
    I1[ASIC]:::thirdParty
  end

  subgraph SONiC Leaf 1
    B2[Fabric Agent]:::ourComponent -->|Scraped by| C2[Alloy]:::thirdParty
    C2 -->|Pushes Logs/Metrics| P
    D2[gNMI]:::thirdParty
    E2[Config DB]:::thirdParty
    I2[ASIC]:::thirdParty
  end

  %% Switch Configuration Flow
  B1 -->|Applies Config| D1
  B2 -->|Applies Config| D2
  D1 -->|Writes/Reads| E1
  D2 -->|Writes/Reads| E2
  E1 -->|Controls| I1
  E2 -->|Controls| I2

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
- **Fabric Proxy**: A pod responsible for collecting logs and metrics from switches (via Alloy) and forwarding them to an external system.
- **Fabricator**: A tool for installing and configuring Fabric, including virtual lab environments.

### SONiC Switch Components
- **Fabric Agent**: Runs on each switch and applies configurations received from the control plane.
- **Alloy**: Collects logs and telemetry data from the switch.
- **gNMI Interface**: The main configuration API used by the Fabric Agent to interact with the switch.
- **Config DB**: The central database in SONiC responsible for maintaining switch configuration.
- **ASIC**: The hardware component handling packet forwarding.

The SONiC architecture presented here is a high-level abstraction, for simplicity.

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

### 4. **Telemetry & Monitoring**
- The **Alloy** agent on the switch collects logs and metrics.
- Logs and metrics are sent to the **Fabric Proxy** running in Kubernetes.
- The **Fabric Proxy** forwards this data to **LGTM**, an external logging and monitoring system.
