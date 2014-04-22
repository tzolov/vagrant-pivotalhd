#!/bin/bash

# oozie_pre_deploy() - 

oozie_pre_deploy() {
   echo "--------------------------------------------------------------------------------"
   echo "                    OOZIE - Pre Deploy                                     "
   echo "--------------------------------------------------------------------------------"

   sed -i "s/<configuration>/\
   \<!-- Configure Hadoop to accept the oozie user to be a proxyuser -->\
   \n<configuration>\
   \n<property>\
   \n    <name>hadoop.proxyuser.oozie.hosts<\/name>\
   \n    <value>*<\/value>\
   \n<\/property>\
   \n<property>\
   \n    <name>hadoop.proxyuser.oozie.groups<\/name>\
   \n    <value>*<\/value>\
   \n<\/property> /g;" /home/gpadmin/ClusterConfigDir/hdfs/core-site.xml
}
 

# oozie_post_deploy() - Deploys the Oozie client and server packages
#
# Arguments:
# - OOZIE_CLIENT - The FQDM of Qozi client node
# - OOZIE_SERVER - The FQDM of Qozi Server node
# - ROOT_PASSWORD - Oozi server root password

oozie_post_deploy() {

   echo "--------------------------------------------------------------------------------"
   echo "                    OOZIE - Post Deploy                                    "
   echo "--------------------------------------------------------------------------------"

   OOZIE_CLIENT="$1"
   OOZIE_SERVER="$2"	
   ROOT_PASSWORD="$3"

   # Deploy Oozie client 
   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $OOZIE_CLIENT 'sudo yum -y install oozie-client'

# Deploy Oozie server
cat > /home/gpadmin/oozie_server_deploy_tmp.sh <<EOF 

sudo yum -y install oozie unzip wget

sudo sed -i "s/<configuration>/\
\<!-- (HUE) Configure Oozie to accept the hue user to be a proxyuser -->\
\n<configuration>\
\n<property>\
\n    <name>oozie.service.ProxyUserService.proxyuser.hue.hosts<\/name>\
\n    <value>*<\/value>\
\n<\/property>\
\n<property>\
\n    <name>oozie.service.ProxyUserService.proxyuser.hue.groups<\/name>\
\n    <value>*<\/value>\
\n<\/property> /g;" /etc/gphd/oozie/conf/oozie-site.xml 

sudo -u hdfs hdfs dfs -mkdir -p /user/oozie
sudo -u hdfs hdfs dfs -chown oozie /user/oozie

sudo service oozie init

wget http://extjs.com/deploy/ext-2.2.zip
mkdir -p /tmp/oozie-libext
mv ext-2.2.zip /tmp/oozie-libext

sudo -u oozie oozie-setup prepare-war -d /tmp/oozie-libext/

EOF

   su - -c "scp ./oozie_server_deploy_tmp.sh gpadmin@$OOZIE_SERVER:/home/gpadmin/oozie_server_deploy_tmp.sh;\
   ssh gpadmin@$OOZIE_SERVER 'chmod a+x /home/gpadmin/oozie_server_deploy_tmp.sh;'" gpadmin

   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $OOZIE_SERVER 'sudo /home/gpadmin/oozie_server_deploy_tmp.sh'
}

# oozie_post_cluster_start() - Completes Oozie server installation
#
# Arguments:
# - OOZIE_SERVER  - The FQDM of Qozi Server node
# - NAME_NODE     - The FQDM of NameNode
# - ROOT_PASSWORD - Oozi server root password

oozie_post_cluster_start() {

   echo "--------------------------------------------------------------------------------"
   echo "                    OOZIE - Post Cluster Start                                "
   echo "--------------------------------------------------------------------------------"

   OOZIE_SERVER="$1"
   NAME_NODE="$2"	
   ROOT_PASSWORD="$3"

cat > /home/gpadmin/oozie_server_post_initialization_tmp.sh <<EOF 
sudo -u oozie oozie-setup sharelib create -fs hdfs://$NAME_NODE:8020 -locallib /usr/lib/gphd/oozie/oozie-sharelib.tar.gz
sudo service oozie start
EOF

   su - -c "\
   scp ./oozie_server_post_initialization_tmp.sh gpadmin@$OOZIE_SERVER:/home/gpadmin/oozie_server_post_initialization_tmp.sh;\
   ssh gpadmin@$OOZIE_SERVER 'chmod a+x /home/gpadmin/oozie_server_post_initialization_tmp.sh;'" gpadmin

   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $OOZIE_SERVER 'sudo /home/gpadmin/oozie_server_post_initialization_tmp.sh'
}