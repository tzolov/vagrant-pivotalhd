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
yum -y install httpd wget python-pip
service httpd start

# Required by the python scripts.
pip install requests

# Prepare a folder to copy the installation tarballs
mkdir /staging
chmod -R a+rx /staging 

# Uncompress the tarballs into the staging area
tar -xvzf /vagrant/packages/PADS-1.3.0.2-14421-rhel5_x86_64.tar.gz -C /staging/
tar -xvzf /vagrant/packages/hawq-plugin-hdp-1.2-133.tar.gz -C /staging/
#FIX!!! cp /vagrant/hawq-plugin-1.2-133.noarch.rpm  /staging/hawq-plugin-hdp-1.2-133/hawq-plugin-1.2-133.noarch.rpm

# Setup internal YUM repositories for the installation packages
/staging/PADS-1.3.0.2/setup_repo.sh  
/staging/hawq-plugin-hdp-1.2-133/setup_repo.sh

# Install Ambari 2.x and HDP 2.x Remote YUM repositories
wget -nv http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.1/ambari.repo -O /etc/yum.repos.d/ambari.repo
wget -nv http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.2.6.0/hdp.repo -O /etc/yum.repos.d/hdp.repo
# http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.6/bk_installing_manually_book/content/config-remote-repositories.html

# Install Spring XD Remote YUM repository
wget -nv http://repo.spring.io/yum-release/spring-xd/1.2/spring-xd-1.2.repo -O /etc/yum.repos.d/spring-xd-1.2.repo

# Install the Ambari Server and Plugins
yum -y install ambari-server

# Copy the JDK7 /Policty tarballs to the Ambari's resouces folder
cp /vagrant/packages/jdk-7u67-linux-x64.tar.gz /var/lib/ambari-server/resources/
cp /vagrant/packages/UnlimitedJCEPolicyJDK7.zip /var/lib/ambari-server/resources/

# Install the Ambari HDP Plugins
yum -y install /staging/hawq-plugin-hdp-1.2-133/hawq-plugin-1.2-133.noarch.rpm
yum -y install spring-xd-plugin-hdp

# Configure and start the Ambari Server
ambari-server setup -s
ambari-server start

# Register the YUM repos with Ambari (shamelessly borrowed from the Pivotal AWS project)
AMBARI_HOSTNAME=ambari.localdomain
STACK_NAME=HDP
STACK_VERSION=2.2
python /vagrant/provision/SetRepos.py $STACK_NAME $STACK_VERSION

# List registered repos
curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://$AMBARI_HOSTNAME:8080/api/v1/stacks/$STACK_NAME/versions/$STACK_VERSION/operating_systems/redhat6/repositories

#Install local Ambari Agent
yum install -y ambari-agent
sudo ambari-agent start
