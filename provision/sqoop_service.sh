#!/bin/bash

# sqoop_post_cluster_start() - Install Sqoop client and sqoop metastore
#
# Arguments:
# - SQOOP_CLIENT  - The FQDM of Sqoop client node
# - SQOOP_METASTORE - Sqoop metastore node FQDM
# - ROOT_PASSWORD - Sqoop metastore server root password

sqoop_post_cluster_start() {

   echo "--------------------------------------------------------------------------------"
   echo "                    Sqoop - Post Cluster Start                                "
   echo "--------------------------------------------------------------------------------"

   SQOOP_CLIENT=$1
   SQOOP_METASTORE=$2
   ROOT_PASSWORD=$3

   # Install Sqoop client packages
   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_CLIENT 'sudo yum -y install sqoop'

   # Install Sqoop metastore packages
   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_METASTORE 'sudo yum -y install sqoop sqoop-metastore'

   # Install Sqoop metastore packages
   sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_METASTORE 'sudo service sqoop-metastore start'
}