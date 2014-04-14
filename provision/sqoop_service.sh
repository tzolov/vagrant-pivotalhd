#!/bin/bash


#######################################################################################
# sqoop_post_initialization() - Install Sqoop client and sqoop metastore
#
# Arguments:
# - SQOOP_CLIENT  - The FQDM of Sqoop client node
# - SQOOP_METASTORE - Sqoop metastore node FQDM
# - ROOT_PASSWORD - Sqoop metastore server root password
#######################################################################################

sqoop_post_initialization() {

echo "********************************************************************************"
echo "*                    Sqoop - Post Initialization                                  "
echo "********************************************************************************"

SQOOP_CLIENT=$1
SQOOP_METASTORE=$2
ROOT_PASSWORD=$3

sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_CLIENT 'sudo yum -y install sqoop'
sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_METASTORE 'sudo yum -y install sqoop sqoop-metastore'

sshpass -p $ROOT_PASSWORD ssh -o StrictHostKeyChecking=no $SQOOP_METASTORE 'sudo service sqoop-metastore start'

}