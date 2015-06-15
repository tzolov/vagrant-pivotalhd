# Installation packages
This folder is a placeholder for the packages and tarballs to be installed. Because of legal restrictions we can not distribute the packages directly. Follow the instructions bellow to collect all neccessary tarballs. 

### Download JDK-7u67 and UnlimitedJCEPolicyJDK7.zip
Execute this command to download Oracla jdk-7u67-linux-x64.tar.gz:
```
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz"
```
Note: The name of the Java JDK tarball is hardcoded in the Ambari setup script to jdk-7u67-linux-x64.tar.gz, which means you need to download the exact same version from Oracle.

Execute this command to download  UnlimitedJCEPolicyJDK7.zip in the packages directory:
```
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
```
### Download Ambari-1.7 and PivotalHD-3.0 tarballs
From https://network.pivotal.io/products/pivotal-hd#/releases/3-0 download the Ambary and PHD3.0 tarballs:
* Pivotal Ambari 1.7.1 (RHEL, CentOS)
* Pivotal HD 3.0 (RHEL, CentOS)
* PHD Utils 1.1.0.20 (RHEL, CentOS)

### Download HAWQ 1.3 tarballs
From https://network.pivotal.io/products/pivotal-hawq#/releases/1-3-0-2/file_groups/270 download the fallowing HAWQ tarballs:
* Pivotal HAWQ Ambari Plugin 1.2 - PHD 3.0
* Pivotal HAWQ 1.3.0.2 (RHEL, CentOS) (r14421)

## Finally the packages folder should those tarballs:
* jdk-7u67-linux-x64.tar.gz
* UnlimitedJCEPolicyJDK7.zip
* AMBARI-1.7.1-87-centos6.tar
* PHD-3.0.0.0-249-centos6.tar
* PHD-UTILS-1.1.0.20-centos6.tar
* PADS-1.3.0.2-14421-rhel5_x86_64.tar.gz
* hawq-plugin-phd-1.2-99.tar.gz
