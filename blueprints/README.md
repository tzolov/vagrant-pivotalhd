## Ambari Blueprints

[Ambari Blueprints](http://docs.hortonworks.com/HDPDocuments/Ambari-1.7.0.0/Ambari_Doc_Suite/ADS_v170.html#ref-63312e0d-d7f1-42b7-9a7e-1663357087f6) provide an API to perform cluster installations. You can build a reusable “blueprint” that defines which Stack to use, how Service Components should be laid-out across a cluster, and what configurations to set.

If you are not familiar with the Blueprints concept check this short but useful article: [Using Ambari Blueprints](https://blog.codecentric.de/en/2014/05/lambda-cluster-provisioning/)

> **Blueprints**: defines the logical structure of a cluster, without needing informations about the actual infrastructure. Therefore you can use the same blueprint for different amount of nodes, different IPs and different domain names.

Couple of predefined blueprint files are provided: `4-node-blueprint.json` (default) and `2-node-blueprint.json` but you can define your own and set the path to it in the `Vagrant` file. 

> **Host Mapping**: The actual cluster creation you also need a second JSON File. Basically the work left is to tell Ambari which blueprint it shoud use and which host should be in which host group. With the attribute `blueprint` you can define the name of the blueprint. Then you can define the hosts of each host group. e.g. we define the host `phd1.localdomain` to be in `host_group_1` of `blueprint-c1` 

Again several host mapping files are provided here: `4-node-blueprint-hostmapping.json` (default) and `2-node-blueprint-hostmapping.json` but you can build your own host mapping file and set the path inthe Vagrant file. 

#### References 
* [Ambari Blueprints API](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints)
