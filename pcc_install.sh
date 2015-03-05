#!/bin/bash
 
# Installing Pivotal Control Center (PCCC)
# 
# Note: The default pwd is /home/vagrant. 
#
# Note: By default, Vagrant shares your project directory (that is the one with the Vagrantfile) 
#       to the /vagrant directory in your guest VMs. 
# 
# Note: 'root' is the default user. You can not change the root user in the script. "$sudo su - gpadmin" will not work!
#       Use the inline syntax instead: "$su - -c "some command" gpadmin".


JAVA_RPM_PATH=$1

PACKAGE_EXTENSION=$2

# Pivotal Control Center (PCC) package name ({PCC_PACKAGE_NAME}.x86_64.{PACKAGE_EXTENSION})
PCC_PACKAGE_NAME=$3

# Pivotal HD (PHD) package name ({PHD_PACKAGE_NAME}.{PACKAGE_EXTENSION})
PHD_PACKAGE_NAME=$4

# HAWQ - Pivotal Advanced Data Service (PADS) package name ({PADS_PACKAGE_NAME}.{PACKAGE_EXTENSION})
PADS_PACKAGE_NAME=$5

# GemfireXD - Pivotal Real-Time Service (PRTS) package name ({PRTS_PACKAGE_NAME}.{PACKAGE_EXTENSION})
PRTS_PACKAGE_NAME=$6
       
# Empty or 'NA' stands for undefined package.
is_package_defined() {
	local package_name="$1"
	if [ ! -z "$package_name" -a "$package_name" != "NA" ]; then
		return 0
	else
		return 1
	fi	
}
 
echo "********************************************************************************"
echo "*               Prepare PCC - Perquisites               "
echo "********************************************************************************"

# Install required packages.
yum -y install httpd mod_ssl postgresql postgresql-devel postgresql-server compat-readline5 createrepo sigar nc expect sudo wget
 
# If missing try to download the Oracle JDK7 installation binary. 
if [ ! -f $JAVA_RPM_PATH ]; then   
   cd /vagrant; wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.rpm"; cd ~
fi
 
# Ensure that all installation packages are available in the same folder where  the 'vagrant up' is executed.
[ ! -f $JAVA_RPM_PATH ] && ( echo "Can not find jdk-7u45-linux-x64.rpm in the vagrant startup directory"; exit 1 )
[ ! -f /vagrant/$PCC_PACKAGE_NAME.x86_64.$PACKAGE_EXTENSION ] && ( echo "Can not find $PCC_PACKAGE_NAME.x86_64.$PACKAGE_EXTENSION in the vagrant startup directory"; exit 1 )
[ ! -f /vagrant/$PHD_PACKAGE_NAME.$PACKAGE_EXTENSION ] && ( echo "Can not find $PHD_PACKAGE_NAME.$PACKAGE_EXTENSION in the vagrant startup directory"; exit 1 )

if (is_package_defined $PADS_PACKAGE_NAME); then
   [ ! -f /vagrant/$PADS_PACKAGE_NAME.$PACKAGE_EXTENSION ] && ( echo "Can not find $PADS_PACKAGE_NAME.$PACKAGE_EXTENSION in the vagrant startup directory"; exit 1 )
fi

if (is_package_defined $PRTS_PACKAGE_NAME); then
   [ ! -f /vagrant/$PRTS_PACKAGE_NAME.$PACKAGE_EXTENSION ] && ( echo "Can not find $PRTS_PACKAGE_NAME.$PACKAGE_EXTENSION in the vagrant startup directory"; exit 1 )
fi
 
# Disable security.
sestatus; chkconfig iptables off; service iptables stop; service iptables status 
 
# Install Oracle Java 7 on PCC (e.g Admin) node.
sudo yum -y install $JAVA_RPM_PATH ; java -version 

echo "********************************************************************************"
echo "*               Install PCC                           "
echo "********************************************************************************"
 
service commander stop
 
# Copy, uncompress and enter the PCC package folder
tar --no-same-owner -xzvf /vagrant/$PCC_PACKAGE_NAME.x86_64.$PACKAGE_EXTENSION --directory /home/vagrant/; cd /home/vagrant/$PCC_PACKAGE_NAME

# Pre-patch before icm is run
#Fix jetty memory settings (2G -> 0.5G)
sudo sed -i "s/service commander start/sed -i \'s\/PRTS-1.3.0 PRTS-1.3\/PRTS-1.3.0 PRTS-1.3.1 PRTS-1.3\/g\' \/etc\/gphd\/gphdmgr\/conf\/compatibleStack.properties; sed -i \'s\/gphdmgr.statusfetch.interval.secs=10\/gphdmgr.statusfetch.interval.secs=30\/g\' \/etc\/gphd\/gphdmgr\/conf\/gphdmgr.properties; sed -i \'s\/-Xmx2048m\/-Xmx512m\/g\' \/usr\/lib\/gphd\/gphdmgr\/bin\/setenv.sh ; service commander start/g" /home/vagrant/$PCC_PACKAGE_NAME/support/install_script 

# Use default settings (e.g. gpadmin home dir ...)
sed -i 's/prompt_until_valid/#prompt_until_valid/g' /home/vagrant/$PCC_PACKAGE_NAME/support/install_script 
 
# Install PCC as root using root's login shell (Note: will not work without the '-' option)
su - -c "cd /home/vagrant/$PCC_PACKAGE_NAME; ./install" root

# Fix a known ICM bug (fix has to e applied before installing the cluster!)
sed -i $'s/\"INSTALL_UNKNOWN\" + \"\x01\"/\"INSTALL_UNKNOWN\" + \"\x01\" + \"\" + \"\x03\"/g' /usr/lib/gphd/gphdmgr/lib/server/StatusFetcher.py
sed -i 's/gphdmgr.statusfetch.interval.secs=10/gphdmgr.statusfetch.interval.secs=30/g' /etc/gphd/gphdmgr/conf/gphdmgr.properties

# Uncomment if you see the 'phd-c1 Status: install_failed' message during deployment
# service commander restart
 
echo "********************************************************************************"
echo "*               Import all RPM Packages                "
echo "********************************************************************************"
  
echo "Import PHD & PADS packages into the PCC local yum repository ..."
 
# (Required) For installing PHD
su - -c "tar -xzf /vagrant/$PHD_PACKAGE_NAME.$PACKAGE_EXTENSION --directory ~; icm_client import -s ./$PHD_PACKAGE_NAME" gpadmin
 
if (is_package_defined $PADS_PACKAGE_NAME); then
  su - -c "tar -xzf /vagrant/$PADS_PACKAGE_NAME.$PACKAGE_EXTENSION --directory ~; icm_client import -s ./$PADS_PACKAGE_NAME" gpadmin
fi
 
if (is_package_defined $PRTS_PACKAGE_NAME); then
  su - -c "tar -xzf /vagrant/$PRTS_PACKAGE_NAME.$PACKAGE_EXTENSION --directory ~; icm_client import -s ./$PRTS_PACKAGE_NAME" gpadmin
fi
   
# Import Java 7 packages in the local yum repo
su - -c "icm_client import -r $JAVA_RPM_PATH" gpadmin

