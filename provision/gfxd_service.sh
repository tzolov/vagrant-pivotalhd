#!/bin/bash


gfxd_pre_deploy() {

   echo "--------------------------------------------------------------------------------"
   echo "                    GemfireXD - Pre Deploy                                       "
   echo "--------------------------------------------------------------------------------"

GFXD_LOCATOR=$1
GFXD_SERVERS=$2
   
if (is_service_enabled "gfxd"); then
sed -i "\
s/<\/hostRoleMapping>/\
\n         <gfxd>\
\n            <gfxd-locator>$GFXD_LOCATOR<\/gfxd-locator>\
\n            <gfxd-server>$GFXD_SERVERS<\/gfxd-server>\
\n         <\/gfxd>\
\n     <\/hostRoleMapping>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
fi   
   
}


gfxd_post_deploy() {

   echo "--------------------------------------------------------------------------------"
   echo "                     GemfireXD - Post Deploy                                      "
   echo "--------------------------------------------------------------------------------"

}

gfxd_post_cluster_start() {

   echo "--------------------------------------------------------------------------------"
   echo "                    GeimfireXD - Post Cluster Start                               "
   echo "--------------------------------------------------------------------------------"
   
   GFXD_LOCATOR=$1
   GFXD_SERVERS=$2
   
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
}