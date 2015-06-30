#!/bin/bash
 
AMBARI_HOSTNAME=$1
AMBARI_HOSTNAME_FQDN=$2
NUMBER_OF_CLUSTER_NODES=$3

# clean the local YUM cache (ls -la /var/cache/yum/x86_64/6/)
yum clean all
rm -Rf /var/cache/yum/x86_64/6/
yum -y update all
yum -y install mysql-connector-java
 
# Install the packages required for all cluster and admin nodes 
yum -y install nc expect ed ntp dmidecode pciutils

# Set timezone and run NTP (set to Europe - Amsterdam time).
/etc/init.d/ntpd stop; 
mv /etc/localtime /etc/localtime.bak; 
ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime; 
/etc/init.d/ntpd start

# Create and set the hosts file like:
#
# 10.211.55.100 ambari.localdomain  ambari
# 10.211.55.101 phd1.localdomain  phd1
# ...
# 10.211.55.10N phdN.localdomain  phdN

cat > /etc/hosts <<EOF 
127.0.0.1     localhost.localdomain    localhost
::1           localhost6.localdomain6  localhost6
 
EOF

echo "10.211.55.100 $AMBARI_HOSTNAME_FQDN  $AMBARI_HOSTNAME" >> /etc/hosts
   
for i in $(eval echo {1..$NUMBER_OF_CLUSTER_NODES}); do 
   echo "10.211.55.$((100 + $i)) phd$i.localdomain phd$i" >> /etc/hosts 
done

# Setup password-less ssh
cp /vagrant/id_dsa.pub /home/vagrant/.ssh/
cat /home/vagrant/.ssh/id_dsa.pub >> /home/vagrant/.ssh/authorized_keys

# Configure Prereqs
/etc/init.d/iptables stop
chkconfig iptables off
echo "umask 022" >> /etc/profile
echo "echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local
echo "echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >> /etc/rc.local
source /etc/rc.local
