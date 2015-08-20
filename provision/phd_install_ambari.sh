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
tar -xvzf /vagrant/packages/AMBARI-1.7.1-88-centos6.tar.gz -C /staging/
tar -xvzf /vagrant/packages/PHD-3.0.1.0-1-centos6.tar.gz -C /staging/
tar -xvzf /vagrant/packages/PHD-UTILS-1.1.0.20-centos6.tar -C /staging/
tar -xvzf /vagrant/packages/PADS-1.3.1.0-15874-rhel5_x86_64.tar -C /staging/
tar -xvzf /vagrant/packages/hawq-plugin-phd-1.3.0-152.tar -C /staging/

# Setup internal YUM repositories for the installation packages
for f in /staging/**/setup_repo.sh
do
 $f
done

# Setup the Remote SpringXD YUM repository
wget -nv http://repo.spring.io/yum-release/spring-xd/1.2/spring-xd-1.2.repo -O /etc/yum.repos.d/spring-xd-1.2.repo

# Install the Ambari Server and Plugins
yum -y install ambari-server

# Copy the JDK7 and the Policty tarballs into Ambari's resouces folder
cp /vagrant/packages/jdk-7u67-linux-x64.tar.gz /var/lib/ambari-server/resources/
cp /vagrant/packages/UnlimitedJCEPolicyJDK7.zip /var/lib/ambari-server/resources/

# Install Ambari Plugins
yum -y install /staging/hawq-plugin-phd-1.3.0/hawq-plugin-1.3.0-152.noarch.rpm
yum -y install spring-xd-plugin-phd

# Set nagios credentials nagiosadmin/admin
htpasswd -c -b  /etc/nagios/htpasswd.users nagiosadmin admin

# Configure and start the Ambari Server
ambari-server setup -s
ambari-server start

# Check the availability of the PHD3.0 Stack
curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://ambari.localdomain:8080/api/v1/stacks/PHD/versions/3.0

# Give Ambari Server few seconds before start using the RSET API
sleep 5

# Register the YUM repos with Ambari (shamelessly borrowed from the Pivotal AWS project)
python /vagrant/provision/SetRepos.py PHD 3.0
# List registered repos
curl --user admin:admin -H 'X-Requested-By:ambari' -X GET http://ambari.localdomain:8080/api/v1/stacks/PHD/versions/3.0/operating_systems/redhat6/repositories


#Install local Ambari Agent
yum install -y ambari-agent
sudo ambari-agent start

# Hits how to uninstall Ambari service
# curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://localhost:8080/api/v1/clusters/cluster1/services/HAWQ
# curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://localhost:8080/api/v1/clusters/cluster1/services/PXF

# java -jar /vagrant/ambari-shell-0.1.DEV.jar --ambari.server=ambari.localdomain --ambari.port=8080 --ambari.user=admin --ambari.password=admin
