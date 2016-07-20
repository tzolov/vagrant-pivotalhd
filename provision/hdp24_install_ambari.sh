#!/bin/bash

# Add SSH passwordless keys
cp /vagrant/id_dsa.pub /home/vagrant/.ssh/
cp /vagrant/id_dsa /home/vagrant/.ssh/
chown vagrant:vagrant /home/vagrant/.ssh/id_dsa*
chmod 400 /home/vagrant/.ssh/id_dsa
cat /vagrant/id_dsa.pub | cat >> ~/.ssh/authorized_keys
 
# Install EPEL repository. Required by the pip (SetRepo.py) and SpringXD
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm      
 
# Install HTTPD service needed for the local YUM repo
yum -y install httpd wget python-pip git
service httpd start

# Required by the python scripts.
pip install requests

# Prepare a folder to copy the installation tarballs
mkdir /staging
chmod -R a+rx /staging 

# Uncompress the tarballs into the staging area
#tar -xvzf /vagrant/packages/PADS-1.3.1.0-15874-rhel5_x86_64.tar -C /staging/
#tar -xvzf /vagrant/packages/hawq-plugin-hdp-1.3.0-190.tar -C /staging/

# Setup internal YUM repositories for the installation packages
#for f in /staging/**/setup_repo.sh
#do
# $f
#done

# Install Ambari 2.x and HDP 2.x Remote YUM repositories
wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.2.2.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.4.2.0/hdp.repo -O /etc/yum.repos.d/hdp.repo
#wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
#wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.0.0/hdp.repo -O /etc/yum.repos.d/hdp.repo

# Install Spring XD Remote YUM repository
#wget -nv http://repo.spring.io/yum-release/spring-xd/1.2/spring-xd-1.2.repo -O /etc/yum.repos.d/spring-xd-1.2.repo

# Install Elasticsearch-On-YARN 
#wget -nv https://bintray.com/big-data/rpm/rpm -O /etc/yum.repos.d/bintray-big-data-rpm.repo

# Add Elasticsearch YARN to the Stack
#yum -y install elasticsearch-yarn-ambari-plugin-hdp23

# Add Apache Geode YARN to the Stack
#yum -y install geode-ambari-plugin-hdp23

# Install the Ambari Server and Plugins
yum -y install ambari-server

# Copy the JDK8 /Policty tarballs to the Ambari's resouces folder

cp /vagrant/packages/jdk-8u40-linux-x64.tar.gz /var/lib/ambari-server/resources/
# http://public-repo-1.hortonworks.com/ARTIFACTS/jce_policy-8.zip to /var/lib/ambari-server/resources/jce_policy-8.zip
cp /vagrant/packages/jce_policy-8.zip /var/lib/ambari-server/resources/


# Install the Ambari HDP Plugins
#yum -y install /staging/hawq-plugin-hdp-1.3.0/hawq-plugin-1.3.0-190.noarch.rpm

# Temporal workaround to support HDP2.3
#yum -y install spring-xd-plugin-hdp23-alpha

# Configure and start the Ambari Server
ambari-server setup -s
ambari-server start

# Check the availability of the HDP2.4 Stack
#curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://ambari.localdomain:8080/api/v1/stacks/HDP/versions/2.4
while [ -n "$(curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://ambari.localdomain:8080/api/v1/stacks/HDP/versions/2.4)" ]; do
  echo "Try again..."
  sleep 2
done

# Give Ambari Server few seconds before start using the RSET API
sleep 15

# Register the YUM repos with Ambari (shamelessly borrowed from the Pivotal AWS project)
python /vagrant/provision/SetRepos.py HDP 2.4

# List registered repos
curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://ambari.localdomain:8080/api/v1/stacks/HDP/versions/2.4/operating_systems/redhat6/repositories

#Install local Ambari Agent
yum install -y ambari-agent
sudo ambari-agent start
