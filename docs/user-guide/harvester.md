# Using VPCs with Harvester

It's an example of how Hedgehog Fabric can be used with Harvester or any hypervisor on the servers connected to Fabric.
It assumes that you have already installed Fabric and have some servers running Harvester attached to it.

You'll need to define `Server` object per each server running Harvester and `Connection` object per each server
connection to the switches.

You can have multiple VPCs created and attached to the `Connections` to this servers to make them available to the VMs
in Harvester or any other hypervisor.

## Congigure Harvester

### Add a Cluster Network

From the "Cluster Network/Confg" side menu. Create a new Cluster Network.

![Harvester Cluster Network](./harvester-cluster-network.png)

Here is what the CRD looks like cleaned up:

```yaml
apiVersion: network.harvesterhci.io/v1beta1
kind: ClusterNetwork
metadata:
  name: testnet
```

### Add a Network Config

By clicking "Create Network Confg". Add your connections and select bonding type.

![Harvester Network Config](./harvester-network-config.png)

The resulting cleaned up CRD:

```yaml
apiVersion: network.harvesterhci.io/v1beta1
kind: VlanConfig
metadata:
  name: testconfig
  labels:
    network.harvesterhci.io/clusternetwork: testnet
spec:
  clusterNetwork: testnet
  uplink:
    bondOptions:
      miimon: 100
      mode: 802.3ad
    linkAttributes:
      txQLen: -1
    nics:
      - enp5s0f0
      - enp3s0f1
```

### Add VLAN based VM Networks

Browse over to "VM Networks" and add one for each Vlan you want to support, assigning them to the cluster network.

![Harvester VM Networks](./harvester-vm-networks.png)
![Harvester VM Network Details](./harvester-vm-network-details.png)

Here is what the CRDs will look like for both vlans:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  labels:
    network.harvesterhci.io/clusternetwork: testnet
    network.harvesterhci.io/ready: 'true'
    network.harvesterhci.io/type: L2VlanNetwork
    network.harvesterhci.io/vlan-id: '1001'
  name: testnet1001
  namespace: default
spec:
  config: >-
    {"cniVersion":"0.3.1","name":"testnet1001","type":"bridge","bridge":"testnet-br","promiscMode":true,"vlan":1001,"ipam":{}}
```

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: testnet1000
  labels:
    network.harvesterhci.io/clusternetwork: testnet
    network.harvesterhci.io/ready: 'true'
    network.harvesterhci.io/type: L2VlanNetwork
    network.harvesterhci.io/vlan-id: '1000'
    #  key: string
  namespace: default
spec:
  config: >-
    {"cniVersion":"0.3.1","name":"testnet1000","type":"bridge","bridge":"testnet-br","promiscMode":true,"vlan":1000,"ipam":{}}
```

### Using the VPCs

Now you can choose created VM Networks when creating a VM in Harvester and have them created as part of the VPC.
