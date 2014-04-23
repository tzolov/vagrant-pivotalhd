#!/bin/bash


graphlab_pre_deploy() {
}


graphlab_post_deploy() {
}

graphlab_post_cluster_start() {

   echo "--------------------------------------------------------------------------------"
   echo "                    GraphLab - Post Cluster Start                               "
   echo "--------------------------------------------------------------------------------"
   
   CLIENT_NODE=$1
   WORKER_NODES=$2
   ROOT_PASSWORD=$3
   
   CLIENT_AND_WORKER_NODES=$CLIENT_NODE,$WORKER_NODES
   
   for graphlab_server in ${CLIENT_AND_WORKER_NODES//,/ }
   do
     echo "Install Hamster and GraphLab  on server: $graphlab_server"  
     sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $graphlab_server 'sudo yum -y install hamster-core openmpi hamster-rte graphlab'
   done
}