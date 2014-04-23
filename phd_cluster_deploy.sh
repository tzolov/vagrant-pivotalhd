#!/bin/bash
 
# Deploy Pivotal HD Cluster and Services
# 
# Note: The default pwd is /home/vagrant. 
#
# Note: By default, Vagrant shares your project directory (that is the one with the Vagrantfile) 
#       to the /vagrant directory in your guest VMs. 
# 
# Note: 'root' is the default user. You can not change the root user in the script. "$sudo su - gpadmin" will not work!
#       Use the inline syntax instead: "$su - -c "some command" gpadmin".

source /vagrant/provision/oozie_service.sh
source /vagrant/provision/hue_service.sh
source /vagrant/provision/sqoop_service.sh
source /vagrant/provision/graphlab_service.sh
source /vagrant/provision/gfxd_service.sh
source /vagrant/provision/hawq_service.sh

[ "$#" -ne 7 ] && (echo "Expects 7 input agreements but found: $#"; exit 1)
  
# Sets the cluster name to be used in PCC (Pivotal Control Center)
CLUSTER_NAME=$1
 
# List of Hadoop services to be deployed with this installation.
# Note: Hive is disabled because phd2 and ph3 VMs are configured with just 1GB of memory (Vagrantfile)! To enable Hive 
# increase the memory of the VMs to 2GB at least (edit Vagrantfile) and then add 'hive' to the $SERVICES variable.
# Alternativly if you don't have enough physical memory then you can remove one VM (phd3 for example) and increase the memory
# of the remaining VMs. For this you need to remove phd3 definition from the Vagrangfile and from the $SLAVE_NODES list.
SERVICES=$2
 
# Sets the dns name of the VM used as Master node for all Hadoop services (e.g. namenode, hawq master, jobtracker ...)
# Note: Master node is not an Admin node (where PCC runs). By convention the Admin node is the pcc.localdomain. 
MASTER_NODE=$3

# List of worker nodes
WORKER_NODES=$4

# Amount of memory allocated for this node (VM)
PHD_MEMORY_MB=$5
 
JAVA_RPM_PATH=$6 

# HDFS replication factor - relative to the number of DataNodes
HDFS_REPLICATION_FACTOR=$7 
 
# By default the HAWQ master is collocated with the other master services.
HAWQ_MASTER=$MASTER_NODE
  
# By default all nodes will be used as Hawq segment hosts. Edit the $HAWQ_SEGMENT_HOSTS variable to change this setup.  
HAWQ_SEGMENT_HOSTS=$WORKER_NODES
 
# Client node defaults to the MASTER node 
CLIENT_NODE=$MASTER_NODE

# By default the GemfireXD Locator is collocated with the other master services.
GFXD_LOCATOR=$MASTER_NODE

# GemfireXD servers. Remove the master node if present
GFXD_SERVERS=${WORKER_NODES/$MASTER_NODE,/}
 
# Root password required for creating gpadmin users on the cluster nodes. 
# (By default Vagrant creates 'vagrant' root user on every VM. The password is 'vagrant' - used below)
ROOT_PASSWORD=vagrant
 
# Non-empty password to be used for the gpadmin user. Required by the PHD installation. 
GPADMIN_PASSWORD=gpadmin

is_service_enabled() {
	local service_name="$1"
	if [[ $SERVICES == *$service_name* ]]
	then
        # enabled
		return 0
	else
        # disabled
		return 1 
	fi	
}

echo "********************************************************************************"
echo "*                 Pre-Deploy Cluster: $CLUSTER_NAME                    "
echo "********************************************************************************"
# Cluster is deployed as gpadmin user!
 
# Pivotal HD manager deploys clusters using input from the cluster configuration directory. This cluster 
# configuration directory contains files that describes the topology and configuration for the cluster and the 
# installation procedure.
 
# Fetch the default Cluster Configuration Templates. 
su - -c "icm_client fetch-template -o ~/ClusterConfigDir" gpadmin
 
# Use the following convention to assign cluster hosts to Hadoop service roles. All changes are 
# applied to the ~/ClusterConfigDir/clusterConfig.xml file, generated in the previous step. 
# Note: By default HAWQ_MASTER=MASTER_NODE, CLIENT_NODE=MASTER_NODE and HAWQ_SEGMENT_HOSTS=WORKER_NODES
# ---------------------------------------------------------------------------------------------------------
#      Hosts        |                       Services
# ---------------------------------------------------------------------------------------------------------
# MASTER_NODE       | client, namenode, secondarynameonde, yarn-resourcemanager, mapreduce-historyserver, 
#                   | hbase-master,hive-server,hive-metastore,hawq-master,hawq-standbymaste,hawq-segment,
#                   | gpxf-agent
#                   |
# WORKER_NODES      | datanode,yarn-nodemanager,zookeeper-server,hbase-regionserver,hawq-segment,gpxf-agent 
# ---------------------------------------------------------------------------------------------------------

# Apply the mapping convention (above) to the default clusterConfig.xml.

# remove services not supported by the clusterConfig.xml
SUPPORTED_SERVICES=$SERVICES; for non_icm_service in 'graphlab' 'oozie' 'hue' 'sqoop'; do SUPPORTED_SERVICES=${SUPPORTED_SERVICES/,$non_icm_service}; done

sed -i "\
s/<clusterName>.*<\/clusterName>/<clusterName>$CLUSTER_NAME<\/clusterName>/g;\
s/<services>.*<\/services>/<services>$SUPPORTED_SERVICES<\/services>/g;\
s/<client>.*<\/client>/<client>$CLIENT_NODE<\/client>/g;\
s/<namenode>.*<\/namenode>/<namenode>$MASTER_NODE<\/namenode>/g;\
s/<datanode>.*<\/datanode>/<datanode>$WORKER_NODES<\/datanode>/g;\
s/<secondarynamenode>.*<\/secondarynamenode>/<secondarynamenode>$MASTER_NODE<\/secondarynamenode>/g;\
s/<yarn-resourcemanager>.*<\/yarn-resourcemanager>/<yarn-resourcemanager>$MASTER_NODE<\/yarn-resourcemanager>/g;\
s/<yarn-nodemanager>.*<\/yarn-nodemanager>/<yarn-nodemanager>$WORKER_NODES<\/yarn-nodemanager>/g;\
s/<mapreduce-historyserver>.*<\/mapreduce-historyserver>/<mapreduce-historyserver>$MASTER_NODE<\/mapreduce-historyserver>/g;\
s/<zookeeper-server>.*<\/zookeeper-server>/<zookeeper-server>$WORKER_NODES<\/zookeeper-server>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
#s/<zookeeper-server>.*<\/zookeeper-server>/<zookeeper-server>$MASTER_NODE<\/zookeeper-server>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml

# Configure the YARN and Heap memory relative to the available VM memory size
nm_resource_memory_mb=$(((PHD_MEMORY_MB / 100) * 95))
scheduler_min_allocation_mb=$(((PHD_MEMORY_MB / 100) * 60))
nm_resource_memory_mb_90_percent=$(((PHD_MEMORY_MB / 100) * 90))
yarn_scheduler_minimum_allocation_mb=$(($nm_resource_memory_mb_90_percent<1024?$nm_resource_memory_mb_90_percent:1024))
heap_memory_mb=$(($nm_resource_memory_mb_90_percent<2048?$nm_resource_memory_mb_90_percent:2048))

sed -i "\
s/<yarn.nodemanager.resource.memory-mb>.*<\/yarn.nodemanager.resource.memory-mb>/<yarn.nodemanager.resource.memory-mb>$nm_resource_memory_mb<\/yarn.nodemanager.resource.memory-mb>/g;\
s/<yarn.scheduler.minimum-allocation-mb>.*<\/yarn.scheduler.minimum-allocation-mb>/<yarn.scheduler.minimum-allocation-mb>$scheduler_min_allocation_mb<\/yarn.scheduler.minimum-allocation-mb>/g;\
s/<dfs.namenode.heapsize.mb>.*<\/dfs.namenode.heapsize.mb>/<dfs.namenode.heapsize.mb>$heap_memory_mb<\/dfs.namenode.heapsize.mb>/g;\
s/<dfs.datanode.heapsize.mb>.*<\/dfs.datanode.heapsize.mb>/<dfs.datanode.heapsize.mb>$heap_memory_mb<\/dfs.datanode.heapsize.mb>/g;\
s/<yarn.resourcemanager.heapsize.mb>.*<\/yarn.resourcemanager.heapsize.mb>/<yarn.resourcemanager.heapsize.mb>$heap_memory_mb<\/yarn.resourcemanager.heapsize.mb>/g;\
s/<yarn.nodemanager.heapsize.mb>.*<\/yarn.nodemanager.heapsize.mb>/<yarn.nodemanager.heapsize.mb>$heap_memory_mb<\/yarn.nodemanager.heapsize.mb>/g;\
s/<hbase.heapsize.mb>.*<\/hbase.heapsize.mb>/<hbase.heapsize.mb>$heap_memory_mb<\/hbase.heapsize.mb>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml

sed -i "s/<\/configuration>/\
\n<property>\n  <name>mapreduce.map.memory.mb<\/name>\n  <value>$nm_resource_memory_mb_90_percent<\/value>\n<\/property>\
\n<property>\n  <name>mapreduce.reduce.memory.mb<\/name>\n  <value>$nm_resource_memory_mb_90_percent<\/value>\n<\/property>\
\n<property>\n  <name>yarn.app.mapreduce.am.resource.mb<\/name>\n  <value>$nm_resource_memory_mb<\/value>\n<\/property>\
\n<\/configuration> /g;" /home/gpadmin/ClusterConfigDir/yarn/mapred-site.xml 

sed -i "s/<\/configuration>/\
\n<property>\n    <name>dfs.replication<\/name>\n    <value>$HDFS_REPLICATION_FACTOR<\/value>\n<\/property>\
\n<\/configuration> /g;" /home/gpadmin/ClusterConfigDir/hdfs/hdfs-site.xml

# Configuration per service

if (is_service_enabled "hbase"); then
   sed -i "\
   s/<hbase-master>.*<\/hbase-master>/<hbase-master>$MASTER_NODE<\/hbase-master>/g;\
   s/<hbase-regionserver>.*<\/hbase-regionserver>/<hbase-regionserver>$WORKER_NODES<\/hbase-regionserver>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi

if (is_service_enabled "hive"); then
   sed -i "\
   s/<hive-server>.*<\/hive-server>/<hive-server>$MASTER_NODE<\/hive-server>/g;\
   s/<hive-metastore>.*<\/hive-metastore>/<hive-metastore>$MASTER_NODE<\/hive-metastore>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi

if (is_service_enabled "hawq"); then
   hawq_pre_deploy $HAWQ_MASTER $HAWQ_SEGMENT_HOSTS
fi

if (is_service_enabled "gfxd"); then
   gfxd_pre_deploy $GFXD_LOCATOR $GFXD_SERVERS
fi

if (is_service_enabled "oozie"); then 
  oozie_pre_deploy
fi

if (is_service_enabled "hue"); then 
  hue_pre_deploy
fi

# clusterConfig.xml wellformness check
xmlwf /home/gpadmin/ClusterConfigDir/clusterConfig.xml  
 
# Set vm.overcommit_memory to 1 to prevent OOM and other VM issues. 
sed -i 's/vm.overcommit_memory = 2/vm.overcommit_memory = 0/g' /usr/lib/gphd/gphdmgr/hawq_sys_config/sysctl.conf

echo "********************************************************************************"
echo "*                 Deploy Cluster: $CLUSTER_NAME                    "
echo "********************************************************************************"

# Use ICM to perform the deploy
# Note: deploy expects user inputs like root and gpadmin passwords. The 'expect' tool is used to emulate this user interaction. 
cat > /home/gpadmin/deploy_cluster.exp <<EOF
#!/usr/bin/expect -f
 
set timeout 100
 
spawn icm_client deploy -c /home/gpadmin/ClusterConfigDir -s -i -d -j $JAVA_RPM_PATH -y /usr/lib/gphd/gphdmgr/hawq_sys_config/
 
expect "Please enter the root password for the cluster nodes:"
send -- "$ROOT_PASSWORD\r"
expect "PCC creates a gpadmin user on the newly added cluster nodes (if any). Please enter a non-empty password to be used for the gpadmin user:"
send -- "$GPADMIN_PASSWORD\r"
send -- "\r"
expect eof
EOF

chown gpadmin:gpadmin /home/gpadmin/deploy_cluster.exp; chmod a+x /home/gpadmin/deploy_cluster.exp
 
# Prepare all PHD hosts and perform the deploy
su - -c "expect -f /home/gpadmin/deploy_cluster.exp" gpadmin

printf "\n"

# Wait until deployment complete (e.g. not in install_progress)
cstatus="unknown"; while [[ "$cstatus" != *"installed"* && "$cstatus" != *"install_failed"* ]]; do cstatus=$(icm_client list | grep "$CLUSTER_NAME"| awk '{ print $11}');  echo "[$(date +'%H:%M:%S')] $CLUSTER_NAME Status: $cstatus "; sleep 20; done

echo "********************************************************************************"
echo "*                 Post-Deploy Cluster: $CLUSTER_NAME                    "
echo "********************************************************************************"

# Fix Hive's java5 override. 
sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $HAWQ_MASTER 'sudo ln -f -s /usr/java/default/bin/java /usr/bin/java'

if (is_service_enabled "oozie"); then
    # Oozie client node, Oozie Server node, Name Node, Root password
    oozie_post_deploy $CLIENT_NODE $MASTER_NODE $ROOT_PASSWORD
fi

if (is_service_enabled "hue"); then
    # Arguments: HUE_SERVER NAME_NODE RESOURCE_MANAGER_NODE HBASE_MASTER ROOT_PASSWORD
    hue_post_deploy $MASTER_NODE $MASTER_NODE $MASTER_NODE $MASTER_NODE $ROOT_PASSWORD
fi

if (is_service_enabled "hawq"); then
   hawq_post_deploy $HAWQ_MASTER $HAWQ_SEGMENT_HOSTS $GPADMIN_PASSWORD
fi
 
echo "********************************************************************************"
echo "*                 Start Cluster: $CLUSTER_NAME                                  "
echo "********************************************************************************"
 
su - -c "icm_client list" gpadmin
  
su - -c "icm_client start -l $CLUSTER_NAME" gpadmin

echo "********************************************************************************"
echo "*                 Post-Start Cluster: $CLUSTER_NAME                             "
echo "********************************************************************************"

if (is_service_enabled "oozie"); then
    # Arguments: Oozie Server node, Name Node, Root password
    oozie_post_cluster_start $MASTER_NODE $MASTER_NODE $ROOT_PASSWORD
fi

if (is_service_enabled "hue"); then
    # Arguments: HUE_SERVER ROOT_PASSWORD
    hue_post_cluster_start $MASTER_NODE $MASTER_NODE $ROOT_PASSWORD
fi

if (is_service_enabled "hawq"); then
   hawq_post_cluster_start
fi

if (is_service_enabled "gfxd"); then
   gfxd_post_cluster_start $GFXD_LOCATOR $GFXD_SERVERS
fi

if (is_service_enabled "graphlab"); then
    #CLIENT_NODE, WORKER_NODES, ROOT_PASSWORD
    graphlab_post_cluster_start $CLIENT_NODE $WORKER_NODES $ROOT_PASSWOR
fi

if (is_service_enabled "sqoop"); then
    # Arguments: SQOOP_CLIENT, SQOO_METASTORE, ROOT_PASSWORD
    sqoop_post_cluster_start $MASTER_NODE $MASTER_NODE $ROOT_PASSWORD
fi
