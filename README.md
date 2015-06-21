Vagrant and Ambari Blueprint API to build PivotalHD3.0/HAWQ cluster
=================
Vagrant scripts that leverage [Apache Ambari](https://ambari.apache.org/) to install [PivotalHD 3.0](http://pivotal.io/big-data/pivotal-hd) Hadoop along with [HAWQ 1.3 (SQL on Hadoop)](http://pivotal.io/big-data/pivotal-hawq) and [Spring XD](http://projects.spring.io/spring-xd/).

The Vagrant scripts uses [Ambari Blueprint API](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints) to specify and deploy the cluster. The logical structure of the cluster is defined in a [`Blueprint`](blueprints) while the [`Host-Mapping`](blueprints) specification defines how a blueprint is mapped into physical machines. The Vagrant script provisions Virtual Machines (VMs) for the hosts defined in the `Host-Mapping` and then uses the Ambari API to deploys the cluster blueprint. 

> After hardware is available and software packages are downloaded, there is a Vagrant-based, single-command install process that will set-up either VMware Fusion VMs or VirtualBox VMs by default with CentOS. 
Default blueprint creates four virtual machines  — one for the Apache Ambari and three for the Pivotal HD cluster where Apache Hadoop® (HDFS, YARN, Pig, Zookeeper, HBase), HAWQ (SQL-on-HDFS analytic data warehouse)

## Prerequisite 
* From a hardware standpoint, you need 64-bit architecture, the four VMs blueprint requires at least 16GB of physical memory and around 120GB of free disc space (you can configure with only 24GB of disc space but you will not be able to install all Pivotal services together.
* Install [Vagrant](http://www.vagrantup.com/downloads.html) (1.7.2+).
* Install [VirtualBox](https://www.virtualbox.org/) or VMware Fusion (note that VMWare Fusion requires [paid Vagrant license](http://www.vagrantup.com/vmware)). 

## Prepare the Vagrant/Blueprints environment
* Clone this project
```
git clone https://github.com/tzolov/vagrant-pivotalhd.git
```
* Follow the [Packages download](https://github.com/tzolov/vagrant-pivotalhd/tree/master/packages) instructions to collect all required tarballs and store them inside the `/packages` subfolder.

## Create Pivotal HD, Hadoop cluster
From the top directory run
```
vagrant up --provider virtualbox
```
Default [`blueprint/host-mapping`](https://github.com/tzolov/vagrant-pivotalhd/tree/master/blueprints#all-phd30-services-specification) will create 4 Virtual Machines (ambari.localdomain, phd1.localdomain, phd2.localdomain and ph3.localdomain) and will install Ambari server. Then the Ambari Blueprint REST API is used to deploy and launch the PHD/HAWQ cluster. 

When the `vagrant up` command completes (~10 min) the VMs are provisioned and the Ambari Server is installed. The cluster deployment is in progrees (~30 min) and you can use the Ambari Web UI to monitor the progress. For this open the ambari page in a browser:
```
https://10.211.55.100:8080
```
(username: `admin`, password: `admin`)



