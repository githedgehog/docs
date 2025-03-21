# Fabric Management

The installation of a Hedgehog Fabric deployment is carried out using Fabricator (hhfab CLI). Once deployed, ongoing operations are managed via the [Kubernetes](https://kubernetes.io) CLI, [`kubectl`](https://kubernetes.io/docs/reference/kubectl/).

In this workflow, the Kubernetes API Server processes the Fabric Custom Resources (CRs) and forwards them to the Fabric Controller. The Fabric Controller then generates the required SONiC configurations and dispatches them to the Fabric Agent, which applies these configurations to the SONiC Config DB via gNMI. Simultaneously, Alloy collects metrics and logs from the SONiC switches, sending this information to the monitoring tools for continuous monitoring.

The diagram below illustrates the general workflow for fabric management as well as the interactions between control plane components and the SONiC switches that form the Fabric.

<div align="center">

```

</div>mermaid
---
align: center
---
graph TD

%% Define the nodes (General Workflow excludes Git & ArgoCD)
User[User]
Kubectl[kubectl]
Fabricator[Fabricator]

%% Control Node components
subgraph ControlNode["Control Node"]
  K8S[Kubernetes API Server]
  FC[Fabric Controller]
  K9s[K9s]
  KubectlFabric["kubectl fabric"]
end

%% SONiC Switch components
subgraph SONiCSwitch["SONiC Switch"]
  FA[Fabric Agent]
  Alloy[Alloy]
  DB[SONiC Config DB]
end

%% External monitoring
Monitoring[Loki/Grafana/Tempo/Mimir]

%% Define the relationships
Kubectl -.->|Direct kubectl commands| K8S
User -.->|CLI| Fabricator
User -.->|CLI| Kubectl
Kubectl -.->|Plugin| KubectlFabric
Fabricator -->|SSH access| K9s
Fabricator -->|Applies CRs| K8S
KubectlFabric -->|Interacts with| K8S
K9s -->|UI Manages| K8S
K8S -->|Sends CRDs| FC
FC -->|Generates SONiC Configs| FA
FA -->|Applies Config via gNMI| DB
FA -->|Reports Metrics| Alloy
Alloy -->|Sends Logs & Metrics| Monitoring
```

</div>

---

### Management Workflow Overview

### **User**
**Creates Fabric CR YAMLs** and commits them to version control.
**Directly interacts with SONiC switches** via the Fabricator CLI.
**Uses [`kubectl`](https://kubernetes.io/docs/reference/kubectl/) and `kubectl fabric`** to interact with the Kubernetes API for fabric resource management.

### **Kubernetes API Server (K8S)**
Part of [Kubernetes](https://kubernetes.io).
Manages Fabric Custom Resources (CRs) and interacts with the **Fabric Controller**.

### **kubectl & kubectl fabric**
[`kubectl`](https://kubernetes.io/docs/reference/kubectl/) is the standard CLI tool for [Kubernetes](https://kubernetes.io).
`kubectl fabric` is a plugin that extends `kubectl` with fabric-specific commands and interacts with the Kubernetes API Server.

### **Fabricator**
CLI tool that provides direct interaction with the Kubernetes API.
Can apply configurations via **SSH access** (using **K9s**) or by directly managing Fabric CRs with YAML files.

### **K9s**
  - **SSH** – SSH into a fabric switch
  - **Serial** – Open a serial connection to a fabric switch
  - **Reboot** – Reboot a fabric switch
  - **Power Reset** Perform a power reset on a fabric switch in the NOS
  - **Reinstall** – Reinstall a fabric switch

### **SONiC Switch Relevant Components**
**Fabric Agent:** Receives configurations from the Fabric Controller and applies them to the SONiC switches via gNMI.
**Alloy:** Monitors SONiC and reports metrics.
**SONiC Config DB:** Stores and manages switch configuration data.

### **Monitoring**
Logs and metrics from SONiC are collected and sent to [Loki](https://grafana.com/oss/loki/) and [Mimir](https://grafana.com/oss/mimir/) for visualization and analysis through [Grafana](https://grafana.com).

---

## **GitOps Functionality (ArgoCD)**

GitOps workflows can be leveraged using [ArgoCD](https://argo-cd.readthedocs.io/en/stable/). This is an alternative approach to show that a Fabric can be used with industry standard tools seamlessly.

**User Actions:**
  - The user **creates Fabric CR YAMLs** and pushes them to a [Git repository](https://git-scm.com) for version control.
**ArgoCD Actions:**
  - [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) monitors the Git repository.
  - ArgoCD **pulls the CRs from Git** and applies them to [Kubernetes](https://kubernetes.io) via the Kubernetes API Server.

<div align="center">

```

</div>mermaid
---
align: center
---
graph TD

%% Define the nodes (GitOps includes Git & ArgoCD)
User[User]
Kubectl[kubectl]
    Git[Git Repository]
ArgoCD[ArgoCD]

%% Control Node components
subgraph ControlNode["Control Node"]
  K8S[Kubernetes API Server]
  FC[Fabric Controller]
end

%% Define the relationships
User -->|Fabric CR YAMLs| Git
Kubectl -.->|Direct kubectl commands| K8S
User -.->|CLI| Kubectl
Git -.->|ArgoCD pulls| ArgoCD
ArgoCD -->|Applies CRs| K8S
K8S -->|Sends CRDs| FC
```

</div>
