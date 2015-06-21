User Vagrant and Ambari Blueprint API to build PivotalHD3.0/HAWQ multi-VMs cluster
=================
This project leverages Vagrant and [Apache Ambari](https://ambari.apache.org/) to install multi-VMs [PivotalHD 3.0](http://pivotal.io/big-data/pivotal-hd) Hadoop cluster including [HAWQ 1.3 (SQL on Hadoop)](http://pivotal.io/big-data/pivotal-hawq) and [Spring XD 1.2](http://projects.spring.io/spring-xd/).

The logical structure of the cluster is defined in a [`Blueprint`](blueprints). Related [`Host-Mapping`](blueprints) defines how the blueprint is mapped into physical machines. The [Vagrantfile](Vagrantfile) script provisions Virtual Machines (VMs) for the hosts defined in the `Host-Mapping` and with the help of the [Ambari Blueprint API](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints) deploys the`Blueprint` in the cluster. 

The default [All-Services-Blueprint](blueprints/all-services-blueprint.json) creates four virtual machines  — one for Apache Ambari and three for the Pivotal HD cluster where Apache Hadoop® (HDFS, YARN, Pig, Zookeeper, HBase), HAWQ (SQL-on-Hadoop) and SpringXD are installed.

## Prerequisite 
* From a hardware standpoint, you need 64-bit architecture, the default blueprint requires at least 16GB of physical memory and around 120GB of free disc space (you can configure with only 24GB of disc space but you will not be able to install all Pivotal services together.
* Install [Vagrant](http://www.vagrantup.com/downloads.html) (1.7.2+).
* Install [VirtualBox](https://www.virtualbox.org/) or VMware Fusion (note that VMWare Fusion requires [paid Vagrant license](http://www.vagrantup.com/vmware)). 

## Environment Setup
* Clone this project
```
git clone https://github.com/tzolov/vagrant-pivotalhd.git
```
* Follow the [Packages download](https://github.com/tzolov/vagrant-pivotalhd/tree/master/packages) instructions to collect all required tarballs and store them inside the `/packages` subfolder.
* Edit the  [Vagrantfile](Vagrantfile) `BLUEPRINT_FILE_NAME` and `HOST_MAPPING_FILE_NAME` properties to select the `Blueprint`/`Host-Mapping` pair to deploy. All blueprints and mapping files are in the [`/blueprint`](blueprints) subfolder. By default the [4 nodes, All-Services](https://github.com/tzolov/vagrant-pivotalhd/tree/master/blueprints#all-services-specification) blueprint is used.

## Create Pivotal HD cluster
From the top directory run
```
vagrant up --provider virtualbox
```

The default [`blueprint/host-mapping`](https://github.com/tzolov/vagrant-pivotalhd/tree/master/blueprints#all-services-specification) will create 4 Virtual Machines. 
When the `vagrant up` command reutrns, the VMs are provisioned, the Ambari Server is installed and the cluster deployment is in progrees. Open the Ambari interface to monitor the deployment progress:
```
https://10.211.55.100:8080
```
(username: `admin`, password: `admin`)



