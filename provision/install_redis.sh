#!/bin/bash
 
# Install Redis server. Used as SpringXD transport.
yum -y install redis
chkconfig redis on
sudo sed -i "s/bind 127.0.0.1/#bind 127.0.0.1/g;" /etc/redis.conf
service redis start
