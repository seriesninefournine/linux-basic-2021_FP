#!/bin/bash

mkdir /var/www
echo "localhost:/httpd_data /var/www glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0" >> /etc/fstab
gluster volume start httpd_data
mount -a

#Устанавливаем httpd + php с необходимыми модулями
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --disable remi-safe
yum-config-manager --enable remi
yum-config-manager --enable remi-php74

yum -y install httpd php74 wget

if [ $NodeIP == "192.168.10.20" ]; then
  mkdir ./glpi
  cd ./glpi
  wget --no-check-certificate https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
  tar -xzf glpi-9.5.5.tgz
  cd ./glpi
fi
