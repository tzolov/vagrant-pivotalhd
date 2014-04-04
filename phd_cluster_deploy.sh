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


[ "$#" -ne 5 ] && (echo "Expects 5 input agreements but found: $#"; exit 1)
 
# Sets the cluster name to be used in PCC (Pivotal Control Center)
CLUSTER_NAME=$1
 
# List of Hadoop services to be deployed with this installation.
# Note: Hive is disabled because phd2 and ph3 VMs are configured with just 1GB of memory (Vagrantfile)! To enable Hive 
# increase the memory of the VMs to 2GB at least (edit Vagrantfile) and then add 'hive' to the $SERVICES variable.
# Alternativly if you don't have enough physical memory then you can remove one VM (phd3 for example) and increase the memory
# of the remaining VMs. For this you need to remove phd3 definition from the Vagrangfile and from the $MASTER_AND_SLAVES list.
SERVICES=$2
 
# Sets the dns name of the VM used as Master node for all Hadoop services (e.g. namenode, hawq master, jobtracker ...)
# Note: Master node is not an Admin node (where PCC runs). By convention the Admin node is the pcc.localdomain. 
MASTER_NODE=$3

# List of worker nodes
SLAVE_NODES=$4

# Amount of memory allocated for this node (VM)
PHD_MEMORY_MB=$5
 
# By default the HAWQ master is collocated with the other master services.
HAWQ_MASTER=$MASTER_NODE
 
# List of all Pivotal HD nodes in the cluster (including the master node)
MASTER_AND_SLAVES=$MASTER_NODE,$SLAVE_NODES
 
# By default all nodes will be used as Hawq segment hosts. Edit the $HAWQ_SEGMENT_HOSTS variable to change this setup.  
HAWQ_SEGMENT_HOSTS=$MASTER_AND_SLAVES
 
# Client node defaults to the MASTER node 
CLIENT_NODE=$MASTER_NODE

# By default the GemfireXD Locator is collocated with the other master services.
GFXD_LOCATOR=$MASTER_NODE

# GemfireXD servers
GFXD_SERVERS=$SLAVE_NODES
 
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
echo "*                 Deploy Cluster: $CLUSTER_NAME                    "
echo "********************************************************************************"
 
# Cluster is deployed as gpadmin user!
 
# Pivotal HD manager deploys clusters using input from the cluster configuration directory. This cluster 
# configuration directory contains files that describes the topology and configuration for the cluster and the 
# installation procedure.
 
# Fetch the default Cluster Configuration Templates. 
su - -c "icm_client fetch-template -o ~/ClusterConfigDir" gpadmin
 
# Use the following convention to assign cluster hosts to Hadoop service roles. All changes are 
# applied to the ~/ClusterConfigDir/clusterConfig.xml file, generated in the previous step. 
# Note: By default HAWQ_MASTER=MASTER_NODE, CLIENT_NODE=MASTER_NODE and HAWQ_SEGMENT_HOSTS=MASTER_AND_SLAVES
# ---------------------------------------------------------------------------------------------------------
#      Hosts        |                       Services
# ---------------------------------------------------------------------------------------------------------
# MASTER_NODE       | client, namenode, secondarynameonde, yarn-resourcemanager, mapreduce-historyserver, 
#                   | hbase-master,hive-server,hive-metastore,hawq-master,hawq-standbymaste,hawq-segment,
#                   | gpxf-agent
#                   |
# MASTER_AND_SLAVES | datanode,yarn-nodemanager,zookeeper-server,hbase-regionserver,hawq-segment,gpxf-agent 
# ---------------------------------------------------------------------------------------------------------

# Apply the mapping convention (above) to the default clusterConfig.xml.
sed -i "\
s/<clusterName>.*<\/clusterName>/<clusterName>$CLUSTER_NAME<\/clusterName>/g;\
s/<services>.*<\/services>/<services>$SERVICES<\/services>/g;\
s/<client>.*<\/client>/<client>$CLIENT_NODE<\/client>/g;\
s/<namenode>.*<\/namenode>/<namenode>$MASTER_NODE<\/namenode>/g;\
s/<datanode>.*<\/datanode>/<datanode>$MASTER_AND_SLAVES<\/datanode>/g;\
s/<secondarynamenode>.*<\/secondarynamenode>/<secondarynamenode>$MASTER_NODE<\/secondarynamenode>/g;\
s/<yarn-resourcemanager>.*<\/yarn-resourcemanager>/<yarn-resourcemanager>$MASTER_NODE<\/yarn-resourcemanager>/g;\
s/<yarn-nodemanager>.*<\/yarn-nodemanager>/<yarn-nodemanager>$MASTER_AND_SLAVES<\/yarn-nodemanager>/g;\
s/<mapreduce-historyserver>.*<\/mapreduce-historyserver>/<mapreduce-historyserver>$MASTER_NODE<\/mapreduce-historyserver>/g;\
s/<zookeeper-server>.*<\/zookeeper-server>/<zookeeper-server>$MASTER_NODE<\/zookeeper-server>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
#s/<zookeeper-server>.*<\/zookeeper-server>/<zookeeper-server>$MASTER_AND_SLAVES<\/zookeeper-server>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml

# Configure the YARN and Heap memory relative to the available VM memory size
nm_resource_memory_mb=$(((PHD_MEMORY_MB / 100) * 90))
nm_resource_memory_mb_85_percent=$(((PHD_MEMORY_MB / 100) * 85))
yarn_scheduler_minimum_allocation_mb=$(($nm_resource_memory_mb_85_percent<1024?$nm_resource_memory_mb_85_percent:1024))
heap_memory_mb=$(($nm_resource_memory_mb_85_percent<2048?$nm_resource_memory_mb_85_percent:2048))

sed -i "\
s/<yarn.nodemanager.resource.memory-mb>.*<\/yarn.nodemanager.resource.memory-mb>/<yarn.nodemanager.resource.memory-mb>$nm_resource_memory_mb<\/yarn.nodemanager.resource.memory-mb>/g;\
s/<yarn.scheduler.minimum-allocation-mb>.*<\/yarn.scheduler.minimum-allocation-mb>/<yarn.scheduler.minimum-allocation-mb>$yarn_scheduler_minimum_allocation_mb<\/yarn.scheduler.minimum-allocation-mb>/g;\
s/<dfs.namenode.heapsize.mb>.*<\/dfs.namenode.heapsize.mb>/<dfs.namenode.heapsize.mb>$heap_memory_mb<\/dfs.namenode.heapsize.mb>/g;\
s/<dfs.datanode.heapsize.mb>.*<\/dfs.datanode.heapsize.mb>/<dfs.datanode.heapsize.mb>$heap_memory_mb<\/dfs.datanode.heapsize.mb>/g;\
s/<yarn.resourcemanager.heapsize.mb>.*<\/yarn.resourcemanager.heapsize.mb>/<yarn.resourcemanager.heapsize.mb>$heap_memory_mb<\/yarn.resourcemanager.heapsize.mb>/g;\
s/<yarn.nodemanager.heapsize.mb>.*<\/yarn.nodemanager.heapsize.mb>/<yarn.nodemanager.heapsize.mb>$heap_memory_mb<\/yarn.nodemanager.heapsize.mb>/g;\
s/<hbase.heapsize.mb>.*<\/hbase.heapsize.mb>/<hbase.heapsize.mb>$heap_memory_mb<\/hbase.heapsize.mb>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml

if (is_service_enabled "hbase"); then
sed -i "\
s/<hbase-master>.*<\/hbase-master>/<hbase-master>$MASTER_NODE<\/hbase-master>/g;\
s/<hbase-regionserver>.*<\/hbase-regionserver>/<hbase-regionserver>$MASTER_AND_SLAVES<\/hbase-regionserver>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi

if (is_service_enabled "hive"); then
sed -i "\
s/<hive-server>.*<\/hive-server>/<hive-server>$MASTER_NODE<\/hive-server>/g;\
s/<hive-metastore>.*<\/hive-metastore>/<hive-metastore>$MASTER_NODE<\/hive-metastore>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi

# <<HAWQ>>
if (is_service_enabled "hawq"); then
sed -i "\
s/<hawq-master>.*<\/hawq-master>/<hawq-master>$HAWQ_MASTER<\/hawq-master>/g;\
s/<hawq-standbymaster>.*<\/hawq-standbymaster>/<hawq-standbymaster>$HAWQ_MASTER<\/hawq-standbymaster>/g;\
s/<hawq-segment>.*<\/hawq-segment>/<hawq-segment>$HAWQ_SEGMENT_HOSTS<\/hawq-segment>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi
# <<HAWQ>>

# <<GFXD>>
if (is_service_enabled "gfxd"); then
sed -i "\
s/<\/hostRoleMapping>/\
\n         <gfxd>\
\n            <gfxd-locator>$GFXD_LOCATOR<\/gfxd-locator>\
\n            <gfxd-server>$GFXD_SERVERS<\/gfxd-server>\
\n         <\/gfxd>\
\n     <\/hostRoleMapping>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi
# <</GFXD>>
 
# Set vm.overcommit_memory to 1 to prevent OOM and other VM issues. 
sed -i 's/vm.overcommit_memory = 2/vm.overcommit_memory = 0/g' /usr/lib/gphd/gphdmgr/hawq_sys_config/sysctl.conf

# Use ICM to perform the deploy
# Note: deploy expects user inputs like root and gpadmin passwords. The 'expect' tool is used to emulate this user interaction. 
cat > /home/gpadmin/deploy_cluster.exp <<EOF
#!/usr/bin/expect -f
 
set timeout 100
 
spawn icm_client deploy -c /home/gpadmin/ClusterConfigDir -s -i -d -j /vagrant/jdk-7u45-linux-x64.rpm -y /usr/lib/gphd/gphdmgr/hawq_sys_config/
 
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
cstatus="unknown"; while [[ "$cstatus" != *"installed"* ]]; do cstatus=$(icm_client list | grep "$CLUSTER_NAME"| awk '{ print $11}');  echo "Cluster $CLUSTER_NAME status: $cstatus"; sleep 10; done

# Fix java 5 override. 
ssh gpadmin@$HAWQ_MASTER 'ln -f -s /usr/java/default/bin/java /usr/bin/java';

# <<HAWQ>>  
if (is_service_enabled "hawq"); then
echo "********************************************************************************"
echo "*                    HAWQ - post deploy configuration                   "
echo "********************************************************************************"

su - -c "echo $HAWQ_SEGMENT_HOSTS  | tr , '\n' > /home/gpadmin/HAWQ_Segment_Hosts.txt" gpadmin
 
su - -c "\
scp /home/gpadmin/HAWQ_Segment_Hosts.txt gpadmin@$HAWQ_MASTER:/home/gpadmin/HAWQ_Segment_Hosts.txt;\
ssh gpadmin@$HAWQ_MASTER 'source /usr/local/hawq/greenplum_path.sh;\
/usr/local/hawq/bin/gpssh-exkeys -f /home/gpadmin/HAWQ_Segment_Hosts.txt -p $GPADMIN_PASSWORD'" gpadmin
fi
# <</HAWQ>>
 
echo "********************************************************************************"
echo "*                 Start Cluster: $CLUSTER_NAME                                  "
echo "********************************************************************************"
 
su - -c "icm_client list" gpadmin
  
su - -c "icm_client start -l $CLUSTER_NAME" gpadmin

# <<HAWQ>>  
if (is_service_enabled "hawq"); then
echo "********************************************************************************"
echo "*                       Initialise HAWQ   									  "
echo "********************************************************************************"

su - -c "ssh gpadmin@$HAWQ_MASTER '/etc/init.d/hawq init'" gpadmin;
fi
# <</HAWQ>>

# <<GFXD>>
if (is_service_enabled "gfxd"); then
echo "********************************************************************************"
echo "*                       Initialise GemFireXD   									  "
echo "********************************************************************************"

echo "Initialize GFXD locator: $GFXD_LOCATOR"
  su - -c "ssh gpadmin@$GFXD_LOCATOR 'export GFXD_JAVA=/usr/java/default/bin/java; mkdir /tmp/locator; \
nohup sqlf locator start -peer-discovery-address=$GFXD_LOCATOR -dir=/tmp/locator -jmx-manager-start=true -jmx-manager-http-port=7075 & '" gpadmin

echo "Start the Pulse monitoring tool by opening: http://10.211.55.101:7075/pulse/clusterDetail.html  username: admin and password: admin. "

for gfxd_server in ${GFXD_SERVERS//,/ }
do
  echo "Initialize GFXD server: $gfxd_server"
  su - -c "ssh gpadmin@$gfxd_server 'export GFXD_JAVA=/usr/java/default/bin/java; mkdir /tmp/server; \
nohup sqlf server start -locators=$GFXD_LOCATOR[10334] -bind-address=$gfxd_server -client-port=1528 -dir=/tmp/server &'" gpadmin
done
fi
# <</GFXD>>