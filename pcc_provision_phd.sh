#!/bin/bash
 
# All configuration and installation  steps applied here follow the PHD installation guide: 
# 
# 
# Note: The default pwd is /home/vagrant. 
#
# Note: By default, Vagrant shares your project directory (that is the one with the Vagrantfile) 
#       to the /vagrant directory in your guest VMs. 
# 
# Note: 'root' is the default user. You can not change the root user in the script. "$sudo su - gpadmin" will not work!
#       Use the inline syntax instead: "$su - -c "some command" gpadmin".

# Pivotal Control Center (PCC) package name ({PCC_PACKAGE_NAME}.x86_64.tar.gz)
PCC_PACKAGE_NAME=$1

# Pivotal HD (PHD) package name ({PHD_PACKAGE_NAME}.tar.gz)
PHD_PACKAGE_NAME=$2

# HAWQ - Pivotal Advanced Data Service (PADS) package name ({PADS_PACKAGE_NAME}.tar.gz)
PADS_PACKAGE_NAME=$3

# GemfireXD - Pivotal Real-Time Service (PRTS) package name ({PRTS_PACKAGE_NAME}.tar.gz)
PRTS_PACKAGE_NAME=$4
 
# Sets the cluster name to be used in PCC (Pivotal Control Center)
CLUSTER_NAME=PHD_C1
 
# List of Hadoop services to be deployed with this installation.
# Note: Hive is disabled because phd2 and ph3 VMs are configured with just 1GB of memory (Vagrantfile)! To enable Hive 
# increase the memory of the VMs to 2GB at least (edit Vagrantfile) and then add 'hive' to the $SERVICES variable.
# Alternativly if you don't have enough physical memory then you can remove one VM (phd3 for example) and increase the memory
# of the remaining VMs. For this you need to remove phd3 definition from the Vagrangfile and from the $MASTER_AND_SLAVES list.
SERVICES=hdfs,yarn,pig,zookeeper,hbase
 
# Sets the dns name of the VM used as Master node for all Hadoop services (e.g. namenode, hawq master, jobtracker ...)
# Note: Master node is not an Admin node (where PCC runs). By convention the Admin node is the pcc.localdomain. 
MASTER_NODE=phd1.localdomain
 
# By default the HAWQ master is collocated with the other master services.
HAWQ_MASTER=$MASTER_NODE
 
# List of all Pivotal HD nodes in the cluster (including the master node)
MASTER_AND_SLAVES=$MASTER_NODE,phd2.localdomain,phd3.localdomain
 
# By default all nodes will be used as Hawq segment hosts. Edit the $HAWQ_SEGMENT_HOSTS variable to change this setup.  
HAWQ_SEGMENT_HOSTS=$MASTER_AND_SLAVES
 
# Client node defaults to the MASTER node 
CLIENT_NODE=$MASTER_NODE

# By default the GemfireXD Locator is collocated with the other master services.
GFXD_LOCATOR=$MASTER_NODE

# GemfireXD servers
GFXD_SERVERS=phd2.localdomain,phd3.localdomain
 
# Root password required for creating gpadmin users on the cluster nodes. 
# (By default Vagrant creates 'vagrant' root user on every VM. The password is 'vagrant' - used below)
ROOT_PASSWORD=vagrant
 
# Non-empty password to be used for the gpadmin user. Required by the PHD installation. 
GPADMIN_PASSWORD=gpadmin

# Empty or 'NA' stands for undefined package
is_package_defined() {
	local package_name="$1"
	if [ ! -z "$package_name" -a "$package_name" != "NA" ]; then
		return 0
	else
		return 1
	fi	
}
 
echo "********************************************************************************"
echo "*               Prepare PCC (Pivotal Control Center)  Perquisites               "
echo "********************************************************************************"

# Install required packages.
yum -y install httpd mod_ssl postgresql postgresql-devel postgresql-server compat-readline5 createrepo sigar nc expect sudo wget
 
# If missing try to download the Oracle JDK7 installation binary. 
if [ ! -f /vagrant/jdk-7u45-linux-x64.rpm ]; then   
   cd /vagrant; wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.rpm"; cd ~
fi
 
# Ensure that all installation packages are available in the same folder where  the 'vagrant up' is executed.
[ ! -f /vagrant/jdk-7u45-linux-x64.rpm ] && ( echo "Can not find jdk-7u45-linux-x64.rpm in the vagrant startup directory"; exit 1 )
[ ! -f /vagrant/$PCC_PACKAGE_NAME.x86_64.tar.gz ] && ( echo "Can not find $PCC_PACKAGE_NAME.x86_64.tar.gz in the vagrant startup directory"; exit 1 )
[ ! -f /vagrant/$PHD_PACKAGE_NAME.tar.gz ] && ( echo "Can not find $PHD_PACKAGE_NAME.tar.gz in the vagrant startup directory"; exit 1 )

if (is_package_defined $PADS_PACKAGE_NAME); then
   [ ! -f /vagrant/$PADS_PACKAGE_NAME.tar.gz ] && ( echo "Can not find $PADS_PACKAGE_NAME.tar.gz in the vagrant startup directory"; exit 1 )
fi

if (is_package_defined $PRTS_PACKAGE_NAME); then
   [ ! -f /vagrant/$PRTS_PACKAGE_NAME.tar.gz ] && ( echo "Can not find $PRTS_PACKAGE_NAME.tar.gz in the vagrant startup directory"; exit 1 )
fi

 
# Disable security.
sestatus; chkconfig iptables off; service iptables stop; service iptables status 
 
# Install Oracle Java 7 on PCC (e.g Admin) node.
sudo yum -y install /vagrant/jdk-7u45-linux-x64.rpm ; java -version 

echo "********************************************************************************"
echo "*                 Install PCC (Pivotal Control Center)                          "
echo "********************************************************************************"
 
service commander stop
 
# Copy, uncompress and enter the PCC package folder
tar --no-same-owner -xzvf /vagrant/$PCC_PACKAGE_NAME.x86_64.tar.gz --directory /home/vagrant/; cd /home/vagrant/$PCC_PACKAGE_NAME
 
# Install PCC as root using root's login shell (Note: will not work without the '-' option)
su - -c "cd /home/vagrant/$PCC_PACKAGE_NAME; ./install" root
 
echo "********************************************************************************"
echo "*                 Prepare Hosts for Cluster: $CLUSTER_NAME                   "
echo "********************************************************************************"
  
echo "Import PHD & PADS packages into the PCC local yum repository ..."
 
# (Required) For installing PHD
su - -c "tar -xzf /vagrant/$PHD_PACKAGE_NAME.tar.gz --directory ~; icm_client import -s ./$PHD_PACKAGE_NAME" gpadmin
 
# <<HAQW>>
# Import HAWQ packages in the local yum repo
if (is_package_defined $PADS_PACKAGE_NAME); then
su - -c "tar -xzf /vagrant/$PADS_PACKAGE_NAME.tar.gz --directory ~; icm_client import -s ./$PADS_PACKAGE_NAME" gpadmin
fi
# <</HAWQ>> 
 
if (is_package_defined $PRTS_PACKAGE_NAME); then
su - -c "tar -xzf /vagrant/$PRTS_PACKAGE_NAME.tar.gz --directory ~; icm_client import -s ./$PRTS_PACKAGE_NAME" gpadmin
fi
 
# (Optional) Import DataLoader and UUS installation packages
#su - -c "tar -xzf /vagrant/PHDTools-1.1.0.0-97.tar.gz --directory ~; icm_client import -p ./PHDTools-1.1.0.0-97" gpadmin
  
# Import Java 7 packages in the local yum repo
su - -c "icm_client import -r /vagrant/jdk-7u45-linux-x64.rpm" gpadmin

echo "********************************************************************************"
echo "*                 Deploy Cluster: $CLUSTER_NAME                    "
echo "********************************************************************************"
 
# Cluster is deployed as gpadmin user!
 
# Create a hostfile (HostFile.txt) that contains the hostnames of all cluster nodes (except pcc) separated by newlines.
# Important: The hostfile should contain all nodes within your cluster EXCEPT the Admin node (e.g. except pcc.localdomain).
su - -c "echo $MASTER_AND_SLAVES  | tr , '\n' > /home/gpadmin/HostFile.txt" gpadmin
    
# Verify that all hosts are prepared for installation
#su - -c "icm_client scanhosts -f ./HostFile.txt" gpadmin

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
s/<zookeeper-server>.*<\/zookeeper-server>/<zookeeper-server>$MASTER_AND_SLAVES<\/zookeeper-server>/g;\
s/<hbase-master>.*<\/hbase-master>/<hbase-master>$MASTER_NODE<\/hbase-master>/g;\
s/<hbase-regionserver>.*<\/hbase-regionserver>/<hbase-regionserver>$MASTER_AND_SLAVES<\/hbase-regionserver>/g;\
s/<hive-server>.*<\/hive-server>/<hive-server>$MASTER_NODE<\/hive-server>/g;\
s/<hive-metastore>.*<\/hive-metastore>/<hive-metastore>$MASTER_NODE<\/hive-metastore>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml

if (is_package_defined $PADS_PACKAGE_NAME); then
sed -i "\
s/<\/services>/,gpxf,hawq<\/services>/g;\
s/<hawq-master>.*<\/hawq-master>/<hawq-master>$HAWQ_MASTER<\/hawq-master>/g;\
s/<hawq-standbymaster>.*<\/hawq-standbymaster>/<hawq-standbymaster>$HAWQ_MASTER<\/hawq-standbymaster>/g;\
s/<hawq-segment>.*<\/hawq-segment>/<hawq-segment>$HAWQ_SEGMENT_HOSTS<\/hawq-segment>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi

if (is_package_defined $PRTS_PACKAGE_NAME); then
sed -i "\
s/<\/services>/,gfxd<\/services>/g;\
s/<\/hostRoleMapping>/\
\n         <gfxd>\
\n            <gfxd-locator>$GFXD_LOCATOR<\/gfxd-locator>\
\n            <gfxd-server>$GFXD_SERVERS<\/gfxd-server>\
\n         <\/gfxd>\
\n     <\/hostRoleMapping>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi
 
# Use ICM to perform the deploy

# Set vm.overcommit_memory to 1 to prevent OOM and other VM issues. 
sed -i 's/vm.overcommit_memory = 2/vm.overcommit_memory = 0/g' /usr/lib/gphd/gphdmgr/hawq_sys_config/sysctl.conf

# Note: preparehosts expects user inputs like root and gpadmin passwords. The 'expect' tool is used to emulate this user interaction. 
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

echo "\n"

# <<HAWQ>>  
if (is_package_defined $PADS_PACKAGE_NAME); then
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

#wait until the cluster is completely installed (e.g. not in install_progress)
time sleep 60;
 
su - -c "icm_client list" gpadmin
  
su - -c "icm_client start -l $CLUSTER_NAME" gpadmin

# <<HAWQ>>  
if (is_package_defined $PADS_PACKAGE_NAME); then
echo "********************************************************************************"
echo "*                       Initialise HAWQ   									  "
echo "********************************************************************************"

su - -c "ssh gpadmin@$HAWQ_MASTER '/etc/init.d/hawq init'" gpadmin;
fi
# <</HAWQ>>

if (is_package_defined $PRTS_PACKAGE_NAME); then
echo "********************************************************************************"
echo "*                       Initialise GemFireXD   									  "
echo "********************************************************************************"

echo "Initialize GFXD locator: " $GFXD_LOCATOR;
  su - -c "ssh gpadmin@$GFXD_LOCATOR 'mkdir /tmp/locator; \
nohup sqlf locator start -peer-discovery-address=$GFXD_LOCATOR -dir=/tmp/locator -jmx-manager-start=true -jmx-manager-http-port=7075 & '" gpadmin


for gfxd_server in ${GFXD_SERVERS//,/ }
do
  echo "Initialize GFXD server: " $gfxd_server;
  su - -c "ssh gpadmin@$gfxd_server 'mkdir /tmp/server; \
nohup sqlf server start -locators=$GFXD_LOCATOR[10334] -bind-address=$gfxd_server -client-port=1528 -dir=/tmp/server &'" gpadmin
done
fi