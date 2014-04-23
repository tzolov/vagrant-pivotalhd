#!/bin/bash


hawq_pre_deploy() {
   echo "--------------------------------------------------------------------------------"
   echo "                    HAWQ - Pre Deploy                                       "
   echo "--------------------------------------------------------------------------------"
   
   HAWQ_MASTER=$1
   HAWQ_SEGMENT_HOSTS=$2
   
   sed -i "\
   s/<hawq-master>.*<\/hawq-master>/<hawq-master>$HAWQ_MASTER<\/hawq-master>/g;\
   s/<hawq-standbymaster>.*<\/hawq-standbymaster>/<hawq-standbymaster>$HAWQ_MASTER<\/hawq-standbymaster>/g;\
   s/<hawq-segment>.*<\/hawq-segment>/<hawq-segment>$HAWQ_SEGMENT_HOSTS<\/hawq-segment>/g;" /home/gpadmin/ClusterConfigDir/clusterConfig.xml
}


hawq_post_deploy() {
   echo "--------------------------------------------------------------------------------"
   echo "                     HAWQ - Post Deploy                                      "
   echo "--------------------------------------------------------------------------------"
   
   HAWQ_MASTER=$1
   HAWQ_SEGMENT_HOSTS=$2
   GPADMIN_PASSWORD=$3
   
   su - -c "echo $HAWQ_SEGMENT_HOSTS  | tr , '\n' > /home/gpadmin/HAWQ_Segment_Hosts.txt" gpadmin
 
   su - -c "\
    scp /home/gpadmin/HAWQ_Segment_Hosts.txt gpadmin@$HAWQ_MASTER:/home/gpadmin/HAWQ_Segment_Hosts.txt;\
    ssh gpadmin@$HAWQ_MASTER 'source /usr/local/hawq/greenplum_path.sh;\
    /usr/local/hawq/bin/gpssh-exkeys -f /home/gpadmin/HAWQ_Segment_Hosts.txt -p $GPADMIN_PASSWORD'" gpadmin
}

hawq_post_cluster_start() {
   echo "--------------------------------------------------------------------------------"
   echo "                    HAWQ - Post Cluster Start                               "
   echo "--------------------------------------------------------------------------------"
   
   su - -c "ssh gpadmin@$HAWQ_MASTER '/etc/init.d/hawq init'" gpadmin;   
}