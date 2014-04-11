#!/bin/bash
 
oozie_deployment() {
	echo "********************************************************************************"
	echo "*                    OOZIE - Deployment                                         "
	echo "********************************************************************************"

	OOZIE_CLIENT="$1"

	OOZIE_SERVER="$2"
	
	ROOT_PASSWORD="$3"

	# Oozie client 
	sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $OOZIE_CLIENT 'sudo yum -y install oozie-client'

	# Oozie server
cat > /home/gpadmin/oozie_server_deploy_tmp.sh <<EOF 

sudo yum -y install oozie unzip wget

sudo sed -i "s/<configuration>/\
\n<configuration>\
\n<property>\
\n    <name>hadoop.proxyuser.oozie.hosts<\/name>\
\n    <value>*<\/value>\
\n<\/property>\
\n<property>\
\n    <name>hadoop.proxyuser.oozie.groups<\/name>\
\n    <value>*<\/value>\
\n<\/property> /g;" /etc/gphd/hadoop/conf/core-site.xml

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


oozie_post_initialization() {
	echo "********************************************************************************"
	echo "*                    OOZIE - Post initialization                                "
	echo "********************************************************************************"

	OOZIE_SERVER="$1"

	NAME_NODE="$2"
	
	ROOT_PASSWORD="$3"

cat > /home/gpadmin/oozie_server_post_initialization_tmp.sh <<EOF 

echo oozie sharelib create
sudo -u oozie oozie-setup sharelib create -fs hdfs://$NAME_NODE:8020 -locallib /usr/lib/gphd/oozie/oozie-sharelib.tar.gz

sudo service oozie start

EOF

	su - -c "\
	scp ./oozie_server_post_initialization_tmp.sh gpadmin@$OOZIE_SERVER:/home/gpadmin/oozie_server_post_initialization_tmp.sh;\
	ssh gpadmin@$OOZIE_SERVER 'chmod a+x /home/gpadmin/oozie_server_post_initialization_tmp.sh;'" gpadmin
	sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $OOZIE_SERVER 'sudo /home/gpadmin/oozie_server_post_initialization_tmp.sh'
}