vagrant-pivotalhd
=================
Vagrant scripts to install PivotalHD 3.0 Hadoop distribution along with HAWQ 1.3 (SQL engine) and Apache Amabri.

> After hardware is available and software packages are downloaded, there is a Vagrant-based, single-command install process that will set-up either VMware Fusion VMs or VirtualBox VMs by default with CentOS. 
In the process, four virtual machines are created—one for the Pivotal Command Center and three for the Pivotal HD cluster where Apache Hadoop® (HDFS, YARN, Pig, Zookeeper, HBase), HAWQ (SQL-on-HDFS analytic data warehouse)

## Prerequisite 
* From a hardware standpoint, you need 64-bit architecture, at least 16GB of physical memory and around 120GB of free disc space (you can configure with only 24GB of disc space but you will not be able to install all Pivotal services together.
* Install [Vagrant](http://www.vagrantup.com/downloads.html) (1.7.2+).
* Install [VirtualBox](https://www.virtualbox.org/) or VMware Fusion (note that VMWare Fusion requires [paid Vagrant license](http://www.vagrantup.com/vmware)). 

## Setup the Vagrant environment
* Clone this project
```
git clone https://github.com/tzolov/vagrant-pivotalhd.git
```
* Forllow the [Packages download](https://github.com/tzolov/vagrant-pivotalhd/tree/master/packages) instructions to collect all reuired tarballs inside the **/packages** subfolder

## Create Hadoop cluster
From the top directory run
```
vagrant up --provider virtualbox
```
This will create 4 Virtual Machines (ambari.localdomain, phd1.localdomain, phd2.localdomain and ph3.localdomain) and will install Ambari server. Then the Ambari Blueprint REST API is used to deploy and lanch the PHD/HAWQ cluster. 

When the **vagrant up** command completes (after ~10 min) the VMs are provisioned and the Ambari Server is installed. The cluster deployment is in progrees (could take ~30 min) and you can use the Ambari Web UI to monitor the progress. For this open the ambari page in a browser:
```
https://10.211.55.100:8080
```
(username: admin, Password: admin)



