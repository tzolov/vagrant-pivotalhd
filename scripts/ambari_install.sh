#!/bin/bash

# Create passwordless sudo user
# yum -y install sudo ;
# useradd gpadmin && echo "gpadmin:gpadmin" | chpasswd && gpasswd -a gpadmin wheel ;
# mkdir -p /home/gpadmin && chown -R gpadmin:gpadmin /home/gpadmin ;
# sed -i "s/Defaults    requiretty.*/# Defaults    requiretty/g" /etc/sudoers ;
# echo '%wheel        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
 
# Ambari only !!!
yum -y install httpd
service httpd start

# cp /vagrant/id_dsa.pub /home/vagrant/.ssh/
# cp /vagrant/id_dsa /home/vagrant/.ssh/

mkdir /staging
chmod -R a+rx /staging 

tar -xvzf /vagrant/packages/AMBARI-1.7.1-87-centos6.tar -C /staging/
tar -xvzf /vagrant/packages/PHD-3.0.0.0-249-centos6.tar -C /staging/
tar -xvzf /vagrant/packages/PHD-UTILS-1.1.0.20-centos6.tar -C /staging/
tar -xvzf /vagrant/packages/PADS-1.3.0.2-14421-rhel5_x86_64.tar.gz -C /staging/
tar -xvzf /vagrant/packages/hawq-plugin-phd-1.2-99.tar.gz -C /staging/

/staging/AMBARI-1.7.1/setup_repo.sh 
/staging/PHD-3.0.0.0/setup_repo.sh 
/staging/PHD-UTILS-1.1.0.20/setup_repo.sh 
/staging/PADS-1.3.0.2/setup_repo.sh  

/staging/hawq-plugin-phd-1.2-99/setup_repo.sh 

# yum --enablerepo=hawq-plugin-phd-1.0-57 clean metadata

# http://ambari.localdomain/AMBARI-1.7.1
# http://ambari.localdomain/PHD-3.0.0.0
# http://ambari.localdomain/PHD-UTILS-1.1.0.20
# http://ambari.localdomain/PADS-1.3.0.0

# java -jar /vagrant/ambari-shell-0.1.DEV.jar --ambari.server=localhost --ambari.port=8080 --ambari.user=admin --ambari.password=admin
# curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://localhost:8080/api/v1/clusters/cluster1/services/HAWQ
# curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://localhost:8080/api/v1/clusters/cluster1/services/PXF

yum -y install ambari-server

yum -y install /staging/hawq-plugin-phd-1.2-99/hawq-plugin-1.2-99.noarch.rpm

cp /vagrant/packages/jdk-7u67-linux-x64.tar.gz /var/lib/ambari-server/resources/
cp /vagrant/packages/UnlimitedJCEPolicyJDK7.zip /var/lib/ambari-server/resources/

# Set nagios credentials nagiosadmin/admin
htpasswd -c -b  /etc/nagios/htpasswd.users nagiosadmin admin

ambari-server setup -s
# ambari-server setup -s --database=postgres --databasehost=ambari.localdomain --databaseport=10432 --databaseusername=ambari --databasepassword=bigdata --databasename=ambari
ambari-server start

# sudo ambari-server stop

# Add SSH passwordless keys
cp /vagrant/id_dsa.pub /home/vagrant/.ssh/
cp /vagrant/id_dsa /home/vagrant/.ssh/
chown vagrant:vagrant /home/vagrant/.ssh/id_dsa*
cat /vagrant/id_rsa.pub | cat >> ~/.ssh/authorized_keys

# Install python-pip and python's requests
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm      
yum -y install python-pip
pip install requests

# Set the local YUM repos
python /vagrant/scripts/SetRepos.py

#Install local ambari-agent
yum install -y ambari-agent
sudo ambari-agent start
