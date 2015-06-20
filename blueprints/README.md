## Ambari Blueprints

[Ambari Blueprints](http://docs.hortonworks.com/HDPDocuments/Ambari-1.7.0.0/Ambari_Doc_Suite/ADS_v170.html#ref-63312e0d-d7f1-42b7-9a7e-1663357087f6) provide an API to perform cluster installations. You can build a reusable “blueprint” that defines which Stack to use, how Service Components should be laid-out across a cluster, and what configurations to set.

#### Blueprints Concepts
With Apache Blueprint you can specify your cluster configuration and logical structure in a `Blueprint` and then define via `Host-Mapping` how this logical structure is mapped into `physical` machines. 

This article ([Using Ambari Blueprints](https://blog.codecentric.de/en/2014/05/lambda-cluster-provisioning/)) introduces the core concepts. Here are some quotes:

> **Blueprints**: defines the logical structure of a cluster, without needing informations about the actual infrastructure. Therefore you can use the same blueprint for different amount of nodes, different IPs and different domain names.

To get you started we provide couple of predefined blueprints: [hdfs-hawq-only-blueprint.json](hdfs-hawq-only-blueprint.json) and [all-phd3-hawq-services-blueprint.json](all-phd3-hawq-services-blueprint.json) (default). You can create your own bluprint and set it via the [Vagrantfile](../Vagrantfile) `BLUEPRINT_FILE` property. 

> **Host Mapping**: The actual cluster creation you also need a second JSON File. Basically the work left is to tell Ambari which blueprint it shoud use and which host should be in which host group. With the attribute `blueprint` you can define the name of the blueprint. Then you can define the hosts of each host group. e.g. we define the host `phd1.localdomain` to be in `host_group_1` of `blueprint-c1` 

Again several host mapping files are provided here: [2-node-simple-hostmapping.json](2-node-simple-hostmapping.json) and [4-node-all-services-hostmapping.json](4-node-all-services-hostmapping.json) (default) but you can build your own host mapping file and set the path via the [Vagrantfile](../Vagrantfile) `HOST_MAPPING_FILE`property. 

_Note: paths to the custom blueprints and host-mapping files has to be relative to the location of the Vagrantfile!_

#### Host Mapping Convention
To simplify the Vagrant and provisioning files the follwoing hostname convention. Use this convention in your **Host Mapping** specs or Vagrantfile will not be able to provision the required VMs. 
* Ambari hostname - defaults to `ambari.localdomain`. You can override the `ambari` prefix via the [Vagrantfile](../Vagrantfile) `AMBARI_HOSTNAME_PREFIX`property. The domain is fixed to `.localdomain`. 
* Cluster hostnames - cluster nodes use this pattern to assigne hostnames: `phd<NodeIndex>.localdomain`. For example for a cluster with N nodes hostnames should look like this: `phd1.localdomain` ... `phdN.localdomain`. The index starts from `1` and increments consequatively (**with no gaps**).  `N` corresponds to the number of cluster nodes (excluding the Ambari node).

Make shure that the Ambari hostname does not overlap with any of the cluster node names. 

## Predefined Bluprints/Host Mapptings

#### Simple HDFS + HAWQ specification. 
Combination of [hdfs-hawq-only-blueprint.json](hdfs-hawq-only-blueprint.json) and [2-node-simple-hostmapping.json](2-node-simple-hostmapping.json) denfine a 2 node cluster with the following layout:

| Host name | Services |
| -------------------|------------------------------|
| ambari.localadmin | Ambari, Nagios, Ganglia, HAWQ SMaster, SNameNode |
| phd1.localadmin | NameNode, DataNode, HAWQ Segment, PXF, HAWQ Master |

#### All PHD3.0 services specification. 
The [all-phd3-hawq-services-blueprint.json](all-phd3-hawq-services-blueprint.json) and [4-node-all-services-hostmapping.json](4-node-all-services-hostmapping.json) spec defines a 4 node cluster with the following layout:

| Host name | Services |
| -------------------|------------------------------|
| ambari.localadmin | Ambari, Nagios, Ganglia |
| phd1.localadmin | HAWQ SMaster, NameNode, HiveServer2, Hive Metastore, ResourceManager, WebHCat Server, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF |
| phd2.localadmin | App Timeline Server, History Server, HBase Master, Oozie Server, SNameNode, Zookeeper Server, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF |
| phd3.localadmin | HAWQ Master, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF |


#### References 
* [Ambari Blueprints API](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints)
