# F.A.Q

## What is the Hedgehog Fabric
The Hedgehog Fabric is a topology of routers arranged in a spine-leaf architecture. A spine-leaf architecture is a type of Clos topology. In a spine-leaf architectures the leaves are usually placed in racks and connected directly to the servers, and spines are connected only to leaves. In a spine-leaf architecture the fundamental unit of connection is a layer 3 route. The Hedgehog Fabric is managed via Kubernetes objects and custom resource definitions.

## Why is a spine-leaf architecture useful
A spine-leaf architecture provides more bandwidth for traffic that is passing between servers inside of a data center, other architectures like core-access-aggregation are setup to provide more bandwidth in and out of the data center. A spine-leaf architecture provides multiple paths between nodes which allows for router maintenance and resilience in the case of failures. The spine-leaf architecture allows allows for multiple points of egress via border leaf nodes. In a spine-leaf architecture the unit of connection is a layer 3 route, this is advantageous to manage traffic ingress or egress as well as quality of service for the applications on the network. To manage the availability of routes usually BGP, OSPF, or IS-IS are used.


## What does it mean to manage my network with Kubernetes

Commonly a network is managed manually via command line interface or with the hardware vendors tools. Managing a small number of switches and routers this way is cumbersome but workable. Managing switches with Kubernetes is similar to managing pods and applications with Kubernetes. If the administrator wants to create a new Nginx pod, they will create the YAML file describing the pod name, the container image, any ports that the pods needs exposed and what namespace to run the pod in. After the YAML file is done a simple `kubectl apply -f nginx.yaml` is all that is needed in order for the pods to be scheduled. 

With the Hedgehog Fabric, the same ideas apply to managing network resources. A YAML file is created to configure a VPC. The YAML file describes the IP address range for the private cloud, the 192.168.0.0/16 space for example. Any VLANS that the private cloud needs can also be configured in the yaml file. After the desired options are in the file a `kubectl apply -f vpc1.yaml` is all that is needed for the configurations to be pushed to the switch and the switch configuration is live.



