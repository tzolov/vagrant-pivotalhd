## Ambari Blueprints

[Ambari Blueprints](http://docs.hortonworks.com/HDPDocuments/Ambari-1.7.0.0/Ambari_Doc_Suite/ADS_v170.html#ref-63312e0d-d7f1-42b7-9a7e-1663357087f6) provide an API to perform cluster installations. You can build a reusable “blueprint” that defines which Stack to use, how Service Components should be laid-out across a cluster, and what configurations to set.

Read this short article: [Using Ambari Blueprints](https://blog.codecentric.de/en/2014/05/lambda-cluster-provisioning/) to get up to speed with the Ambari Blueprint concepts. 

> **Blueprints**: defines the logical structure of a cluster, without needing informations about the actual infrastructure. Therefore you can use the same blueprint for different amount of nodes, different IPs and different domain names.

Couple of predefined blueprint files are provided: [hdfs-hawq-only-blueprint.json](hdfs-hawq-only-blueprint.json) and [all-phd3-hawq-services-blueprint.json](all-phd3-hawq-services-blueprint.json) (default) but you can define your own and set the path via the [Vagrantfile](../Vagrantfile) `BLUEPRINT_FILE` property. 

> **Host Mapping**: The actual cluster creation you also need a second JSON File. Basically the work left is to tell Ambari which blueprint it shoud use and which host should be in which host group. With the attribute `blueprint` you can define the name of the blueprint. Then you can define the hosts of each host group. e.g. we define the host `phd1.localdomain` to be in `host_group_1` of `blueprint-c1` 

Again several host mapping files are provided here: [2-node-simple-hostmapping.json](2-node-simple-hostmapping.json) and [4-node-all-services-hostmapping.json](4-node-all-services-hostmapping.json) (default) but you can build your own host mapping file and set the path via the [Vagrantfile](../Vagrantfile) `HOST_MAPPING_FILE`property. 

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
