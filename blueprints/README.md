## Ambari Blueprints

[Ambari Blueprints](http://docs.hortonworks.com/HDPDocuments/Ambari-1.7.0.0/Ambari_Doc_Suite/ADS_v170.html#ref-63312e0d-d7f1-42b7-9a7e-1663357087f6) provide an API to perform cluster installations. You can build a reusable “blueprint” that defines which Stack to use, how Service Components should be laid-out across a cluster, and what configurations to set.

#### Concepts
The `Blueprint` defines the logical structure of a cluster while the `Host-Mapping` specifies how this logical structure is mapped into `physical` machines. 

The [Using Ambari Blueprints](https://blog.codecentric.de/en/2014/05/lambda-cluster-provisioning/) article provides a nice introduction of the core concepts.

###### Blueprints
> defines the logical structure of a cluster, without needing informations about the actual infrastructure. Therefore you can use the same blueprint for different amount of nodes, different IPs and different domain names.

Couple of predefined blueprints are provided in the [Predefined Blueprints and Host Mapptings](#predefined-blueprints-and-host-mapptings) section, but can create your own blueprint file and select it through the [Vagrantfile](../Vagrantfile) `BLUEPRINT_FILE_NAME` property. 

###### Host Mapping
> Tells Ambari which blueprint it shoud use and which host should be in which host group. With the attribute `blueprint` you can define the name of the blueprint. Then you can define the hosts of each host group. e.g. we define the host `phd1.localdomain` to be in `host_group_1` of `blueprint-c1` 

Several predefined host-mapping files are provided in the [Predefined Blueprints and Host Mapptings](#predefined-blueprints-and-host-mapptings). You can build your own host-mapping file and select it through the [Vagrantfile](../Vagrantfile) `HOST_MAPPING_FILE_NAME` property. 

###### Stacks
Currently the following stacks are supported: 
* PHD3.0 - PivotalHD 3.0, Ambari 1.7
* HDP2.2 - Hortonworks 2.2, Ambari 2.0.1
_Note: All custom `blueprints` and `host-mapping` files must be stored in the `/blueprints` subfolder!_

#### Host Mapping Name Convention
To simplify the Vagrantfile the follwoing hostname convention is enforced:

* Ambari hostname - defaults to `ambari.localdomain`. You can override the `ambari` prefix via the [Vagrantfile](../Vagrantfile) `AMBARI_HOSTNAME_PREFIX`property. The domain is fixed to `.localdomain`. 
* Cluster hostnames - cluster nodes are named like this: `phd<NodeIndex>.localdomain`. For a cluster with N nodes, the hostnames are: `phd1.localdomain` ... `phdN.localdomain`. Index starts from `1` and increments consequatively (**no gaps**) to N. `N` is the size of the cluster excluding the Ambari node.

Follow this convention in your **Host Mapping** specs or Vagrantfile will not be able to provision the required VMs. If you alter the Ambari name make shure it does not overlap with any of the cluster node names. 

## Predefined Blueprints and Host Mapptings

#### Pivotal HD3.0, Ambari 1.7 Blueprints

###### HDFS and HAWQ Blueprint 
The [phd-hdfs-hawq-blueprint.json](phd-hdfs-hawq-blueprint.json),  [2-node-hdfs-hawq-blueprint-hostmapping.json](2-node-hdfs-hawq-blueprint-hostmapping.json) pair defines a two node cluster with the following layout:
<table>
	<thead>
		<tr>
			<th><sub>Host name</sub></th>
			<th><sub>Host Group</sub></th>
			<th><sub>Components</sub></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><sub>ambari.localadmin</sub></td>
			<td><sub>management_smasters</sub></td>
			<td><sub>Ambari, Nagios, Ganglia, HAWQ SMaster, SNameNode</sub></td>
		</tr>
		<tr>
			<td><sub>phd1.localadmin</sub></td>
			<td><sub>masters_workers</sub></td>
			<td><sub>NameNode, DataNode, HAWQ Segment, PXF, HAWQ Master</sub></td>
		</tr>
	</tbody>
</table>	

###### All services: PivotalHD3.0, HAWQ and SpringXD. 
The [phd-all-services-blueprint.json](phd-all-services-blueprint.json) and [4-node-all-services-hostmapping.json](4-node-all-services-hostmapping.json) spec defines a 4 node cluster with the following layout:
<table>
	<thead>
		<tr>
			<th><sub>Host name</sub></th>
			<th><sub>Host Group</sub></th>
			<th><sub>Components</sub></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><sub>ambari.localadmin</sub></td>
			<td><sub>ambari_gang_nag_knox_clients_group</sub></td>
			<td><sub>Ambari, Nagios, Ganglia</sub></td>
		</tr>
		<tr>
			<td><sub>phd1.localadmin</sub></td>
			<td><sub>nn_yarn_hive_hcat_workers_clients_group</sub></td>
			<td><sub>HAWQ SMaster, NameNode, HiveServer2, Hive Metastore, ResourceManager, WebHCat Server, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF</sub></td>
		</tr>
		<tr>
			<td><sub>phd2.localadmin</sub></td>
			<td><sub>hbase_hist_shawq_spring_xd_workers_clients_group</sub></td>
			<td><sub>App Timeline Server, History Server, HBase Master, Oozie Server, SNameNode, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF</sub></td>
		</tr>		
		<tr>
			<td><sub>phd3.localadmin</sub></td>
			<td><sub>hawq_zk_snn_workers_clients_group</sub></td>
			<td><sub>HAWQ Master, Zookeeper Server, DataNode, HAWQ Segment, RegionServer, NodeManager, PXF</sub></td>
		</tr>		
	</tbody>
</table>


###### SpringXD, YARN, HDFS, HAWQ Blueprint. 
The [phd-springxd-hdfs-yarn-zk-hawq-blueprint.json](phd-springxd-hdfs-yarn-zk-hawq-blueprint.json) and [3-node-springxd-hdfs-yarn-zk-hawq-blueprint-hostmapping.json](3-node-springxd-hdfs-yarn-zk-hawq-blueprint-hostmapping.json) spec defines a 3 node cluster with the following layout:
<table>
	<thead>
		<tr>
			<th><sub>Host name</sub></th>
			<th><sub>Host Group</sub></th>
			<th><sub>Components</sub></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><sub>ambari.localadmin</sub></td>
			<td><sub>management_group</sub></td>
			<td><sub>Ambari, Nagios, Ganglia</sub></td>
		</tr>
		<tr>
			<td><sub>phd1.localadmin</sub></td>
			<td><sub>masters_group</sub></td>
			<td><sub>HAWQ Master, App Timeline Server, History Server, NameNode, ResourceManager, SpringXdAdmin, SpringXdHsql, DataNode, HAWQ Segment, NodeManager, PXF, SpringXdContainer, Zookeeper Server</sub></td>
		</tr>
		<tr>
			<td><sub>phd2.localadmin</sub></td>
			<td><sub>standby_masters_group</sub></td>
			<td><sub>HAWQ SMaster, SNameNode DataNode, HAWQ Segment, NodeManager, PXF, SpringXdContainer</sub></td>
		</tr>		
	</tbody>
</table>

#### Hortonworks HDP2.2, Ambari-2.0 Blueprints

###### SpringXD, YARN, HDFS Blueprint. 
The [hdp-hdfs-yarn-springxd-zk-blueprint.json](hdp-hdfs-yarn-springxd-zk-blueprint.json) and [3-node-springxd-hdfs-yarn-zk-hawq-blueprint-hostmapping.json](3-node-springxd-hdfs-yarn-zk-hawq-blueprint-hostmapping.json) spec defines a 2 node cluster with the following layout:
<table>
	<thead>
		<tr>
			<th><sub>Host name</sub></th>
			<th><sub>Host Group</sub></th>
			<th><sub>Components</sub></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td><sub>ambari.localadmin</sub></td>
			<td><sub>management_group</sub></td>
			<td><sub>Ambari, SNameNode</sub></td>
		</tr>
		<tr>
			<td><sub>phd1.localadmin</sub></td>
			<td><sub>masters_group</sub></td>
			<td><sub>App Timeline Server, History Server, NameNode, ResourceManager, SpringXdAdmin, SpringXdHsql, DataNode, NodeManager, SpringXdContainer, Zookeeper Server, Metrics Collector</sub></td>
		</tr>
	</tbody>
</table>

#### References 
* [Ambari Blueprints API](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints)
