# Frequently Asked Questions (FAQ)

## What is the Hedgehog Fabric?

The Hedgehog Fabric is a topology of routers arranged in a spine-leaf architecture. A spine-leaf architecture is a type of [Clos network topology](https://en.wikipedia.org/wiki/Clos_network). In a spine-leaf architecture, the leaves are usually placed in racks and connected directly to the servers, whereas spines are connected only to leaves. In a spine-leaf architecture, the fundamental unit of connection is a layer 3 route.

The Hedgehog Fabric is managed via Kubernetes objects and custom resource definitions.

## What are the advantages of a spine-leaf architecture?

A spine-leaf architecture provides more bandwidth for traffic that is passing between servers inside of a data center, other architectures like core-access-aggregation are setup to provide more bandwidth in and out of the data center. A spine-leaf architecture provides multiple paths between nodes which allows for router maintenance and resilience in the case of failures. The spine-leaf architecture allows allows for multiple points of egress via border leaf nodes. In a spine-leaf architecture the unit of connection is a layer 3 route, this is advantageous to manage traffic ingress or egress as well as quality of service for the applications on the network. To manage the availability of routes usually BGP, OSPF, or IS-IS are used.


## What does it mean to manage my network with Kubernetes?

A common way to manage a network is to proceed manually via the command-line interface of the equipment, or with the hardware vendor tools. Managing a small number of switches and routers this way is workable, but cumbersome, and it only gets more painful when the network grows. Managing switches and servers with Kubernetes is similar to managing pods and applications with Kubernetes: it provides assistance for deployment, scaling, and management of the network appliances.

For example, if the administrator of a Kubernetes cluster wants to create a new Nginx pod, they write down the YAML file describing the pod name, the container image, any ports that the pod needs exposed, and what namespace to run the pod in. After the YAML file is created, a simple `kubectl apply -f nginx.yaml` is all that the administrator needs to run in order for the pod to be scheduled. 

With the Hedgehog Fabric, the same principles apply to managing network resources. Administrators create a YAML file to configure a VPC. The YAML file describes the IP address range for the private cloud, for example the `192.168.0.0/16` space. It also describes any VLANs that the private cloud needs. After the desired options are in the file, administrators can push the configuration to the switch with a mere `kubectl apply -f vpc1.yaml`, and within a few seconds the switch configuration is live.
