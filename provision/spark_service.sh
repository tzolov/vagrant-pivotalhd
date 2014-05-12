#!/bin/bash


spark_pre_deploy() {

   echo "--------------------------------------------------------------------------------"
   echo "                    Spark - Pre Deploy                                       "
   echo "--------------------------------------------------------------------------------"   
}


spark_post_deploy() {

   echo "--------------------------------------------------------------------------------"
   echo "                     Spark - Post Deploy                                      "
   echo "--------------------------------------------------------------------------------"

}

spark_post_cluster_start() {

   echo "--------------------------------------------------------------------------------"
   echo "                    Spark - Post Cluster Start                               "
   echo "--------------------------------------------------------------------------------"

   SPARK_MASTER=$1
   
   # Sark 0.9.1   
   #SPARK_TAR_GZ_NAME=spark-0.9.1-bin-hadoop22   
   #SPARK_FOLDER_NAME=spark-0.9.1-bin-hadoop2
   #SPARK_JAR=/home/gpadmin/spark-0.9.1-bin-hadoop2/assembly/target/scala-2.10/spark-assembly_2.10-0.9.1-hadoop2.2.0.jar \
   #SPARK_YARN_APP_JAR=/home/gpadmin/spark-0.9.1-bin-hadoop2/examples/target/scala-2.10/spark-examples_2.10-assembly-0.9.1.jar \
   #SPARK_SHELL=/home/gpadmin/spark-0.9.1-bin-hadoop2/bin/spark-shell

   # Sark 1.0.0-RC3   
   SPARK_FOLDER_NAME=spark-1.0.0-rc3-phd20-1
   SPARK_TAR_GZ_NAME=spark-1.0.0-rc3-phd20-1
   SPARK_JAR=/home/gpadmin/spark-1.0.0-rc3-phd20-1/assembly/target/scala-2.10/spark-assembly-1.0.0-SNAPSHOT-hadoop2.2.0.jar
   SPARK_YARN_APP_JAR=/home/gpadmin/spark-1.0.0-rc3-phd20-1/examples/target/scala-2.10/spark-examples-1.0.0-SNAPSHOT-hadoop2.2.0.jar
   SPARK_SHELL=/home/gpadmin/spark-1.0.0-rc3-phd20-1/bin/spark-shell
         
   echo "Download Sark binary packages to $SPARK_MASTER"   
   su - -c "ssh gpadmin@$SPARK_MASTER ' \
   sudo yum -y install wget ; \
   if [ ! -f /home/gpadmin/$SPARK_TAR_GZ_NAME.tar.gz ]; then \
      wget https://dl.dropboxusercontent.com/u/79241625/spark/$SPARK_TAR_GZ_NAME.tar.gz; \
   fi; \
   if [ ! -f /home/gpadmin/$SPARK_TAR_GZ_NAME ]; then \
      tar -xzf /home/gpadmin/$SPARK_TAR_GZ_NAME.tar.gz; \
   fi; '" gpadmin

cat > /home/gpadmin/start-spark-shell.sh <<EOF    
export HADOOP_CONF_DIR=/etc/gphd/hadoop/conf ; \   
SPARK_YARN_MODE=true \
SPARK_JAR=$SPARK_JAR \
SPARK_YARN_APP_JAR=$SPARK_YARN_APP_JAR \
MASTER=yarn-client $SPARK_SHELL
EOF

   su - -c "\
   scp /home/gpadmin/start-spark-shell.sh gpadmin@$SPARK_MASTER:/home/gpadmin/start-spark-shell.sh; \
   ssh gpadmin@$SPARK_MASTER 'chmod a+x /home/gpadmin/start-spark-shell.sh;'" gpadmin 
   
}