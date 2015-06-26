#!/bin/bash 

# Install, configure and start Ambari Agent on every cluster host [phd1 ... phdN]
for i in $(eval echo {1..$1}); do 
  su - -c "ssh -o StrictHostKeyChecking=no vagrant@phd$i.localdomain 'sudo ls;'" vagrant
  su - -c "scp /etc/yum.repos.d/ambari.repo vagrant@phd$i.localdomain:" vagrant
  su - -c "ssh -o StrictHostKeyChecking=no vagrant@phd$i.localdomain 'sudo cp ~/ambari.repo /etc/yum.repos.d/;'" vagrant

  su - -c "ssh -o StrictHostKeyChecking=no vagrant@phd$i.localdomain 'sudo yum -y install ambari-agent;'" vagrant
  su - -c "ssh -o StrictHostKeyChecking=no vagrant@phd$i.localdomain 'sudo sed -i 16s/.*/hostname=ambari.localdomain/ /etc/ambari-agent/conf/ambari-agent.ini;' " vagrant
  su - -c "ssh -o StrictHostKeyChecking=no vagrant@phd$i.localdomain 'sudo ambari-agent start ;'" vagrant
done
