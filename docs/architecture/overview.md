# Overview

The Hedgehog Fabric uses Kubernetes to orchestrate the management of network switches and the configuration. The fabric deploys an agent that runs on each networking switch to configure and monitor the switch. The agent is similar to a kubelet that runs on a server in a Kubernetes cluster, but the Hedgehog Fabric and the agent do not deploy pods to the switch, it is not a schedule-able entity like a server is in a normal Kubernetes cluster.

The Fabric extends Kubernetes through [custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/). The custom resource objects are documented in the [user guide](../user-guide/overview.md). The composable elements in the Fabric are [connections](../user-guide/connections.md), [vpcs](../user-guide/vpcs.md) and [devices](../user-guide/devices.md). 


