#!/bin/bash

#######################################################################################
# hue_pre_deployment() - HUE server configurations before deployment
#######################################################################################

hue_pre_deployment() {

echo "********************************************************************************"
echo "*                    HUE - Pre Deployment                                         "
echo "********************************************************************************"


sed -i "\
s/<configuration>/\
\n<configuration>\
\n<property>\
\n    <name>hadoop.proxyuser.hue.hosts<\/name>\
\n    <value>*<\/value>\
\n<\/property>\
\n<property>\
\n    <name>hadoop.proxyuser.hue.groups<\/name>\
\n    <value>*<\/value>\
\n<\/property> /g;" /home/gpadmin/ClusterConfigDir/hdfs/core-site.xml

sed -i "s/<configuration>/\
\n<configuration>\
\n<property>\
\n    <name>dfs.webhdfs.enabled<\/name>\
\n    <value>true<\/value>\
\n<\/property> /g;" /home/gpadmin/ClusterConfigDir/hdfs/hdfs-site.xml

}

#######################################################################################
# hue_deployment() - Deploys the HUE server packages
#
# Arguments:
# - HUE_SERVER - HUE Server node FQDM
# - NAME_NODE - Cluster NameNode FQDM
# - RESOURCE_MANAGER_NODE - Yarn ResourceManager FQDM
# - HBASE_MASTER - HBase master node FQDM
# - ROOT_PASSWORD - HUE server root password
#######################################################################################

hue_deployment() {

echo "********************************************************************************"
echo "*                    HUE - Deployment                                         "
echo "********************************************************************************"

HUE_SERVER=$1
NAME_NODE=$2
RESOURCE_MANAGER_NODE=$3
HBASE_MASTER=$4
ROOT_PASSWORD=$5

cat > /home/gpadmin/hue_deployment.sh <<EOF

sudo yum -y install ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel rsync

sudo wget https://dl.dropboxusercontent.com/u/730827/hue/releases/3.5.0/hue-3.5.0.tgz; 
tar xf hue*;
cd hue-3.5.0; 

sudo PREFIX=/usr/share make install; 

cd /usr/share/hue; 

sudo useradd hue; 

sudo chown -R hue.hue /usr/share/hue 

sudo sed -i "s/## server_user=hue/server_user=hue/g;" /usr/share/hue/desktop/conf/hue.ini
sudo sed -i "s/## server_group=hue/server_group=hue/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/fs_defaultfs=hdfs:\/\/localhost:8020/fs_defaultfs=hdfs:\/\/$NAME_NODE:8020/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/## webhdfs_url=http:\/\/namenode:50070\/webhdfs\/v1/webhdfs_url=http:\/\/$NAME_NODE:50070\/webhdfs\/v1/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/## resourcemanager_host=localhost/resourcemanager_host=$RESOURCE_MANAGER_NODE/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/## resourcemanager_api_url=http:\/\/localhost:8088/resourcemanager_api_url=http:\/\/$RESOURCE_MANAGER_NODE:8088/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/# history_server_api_url=http:\/\/localhost:19888/history_server_api_url=http:\/\/$RESOURCE_MANAGER_NODE:19888/g;" /usr/share/hue/desktop/conf/hue.ini 
sudo sed -i "s/## hbase_clusters=(Cluster|localhost:9090)/hbase_clusters=(Cluster|$HBASE_MASTER:9090)/g;" /usr/share/hue/desktop/conf/hue.ini 

sudo sed -i "s/## server_url=http:\/\/localhost:12000\/sqoop/server_url=http:\/\/$NAME_NODE:12000\/sqoop/g;" /usr/share/hue/desktop/conf/hue.ini 
  

EOF

su - -c "scp ./hue_deployment.sh gpadmin@$MASTER_NODE:/home/gpadmin/hue_deployment.sh;ssh gpadmin@$MASTER_NODE 'chmod a+x /home/gpadmin/hue_deployment.sh;'" gpadmin

sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $MASTER_NODE 'sudo /home/gpadmin/hue_deployment.sh'

}

#######################################################################################
# hue_post_initialization() - Completes HUE server installation
#
# Arguments:
# - HUE_SERVER  - The FQDM of HUE server node
# - HBASE_MASTER - HBase master node FQDM
# - ROOT_PASSWORD - Oozi server root password
#######################################################################################

hue_post_initialization() {

echo "********************************************************************************"
echo "*                    HUE - Post Initialization                                  "
echo "********************************************************************************"

HUE_SERVER=$1
HBASE_MASTER=$2
ROOT_PASSWORD=$3

su - -c "ssh gpadmin@$HBASE_MASTER 'nohup /usr/bin/hbase thrift start > /dev/null 2>&1 &'" gpadmin

sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $HUE_SERVER 'nohup sudo /usr/share/hue/build/env/bin/supervisor > /dev/null 2>&1 &'

}