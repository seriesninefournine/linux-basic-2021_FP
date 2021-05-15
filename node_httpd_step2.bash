#!/bin/bash

gluster volume start httpd_data
mkdir /var/www
echo 'localhost:/httpd_data /var/www glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
mount -a

#Устанавливаем httpd + php с необходимыми модулями
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --disable remi-safe
yum-config-manager --enable remi
yum-config-manager --enable remi-php74

yum -y install httpd php74