#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
systemctl stop firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release centos-release-gluster6 yum-utils
yum -y install ntp ntpdate glusterfs-server
systemctl enable ntpd
systemctl start ntpd
ntpdate -s ntp.ubuntu.com
sleep 15

#добавляем адреса узлов кластера
echo "
192.168.10.20 node02.local 
192.168.10.21 node03.local 
192.168.10.23 node04.local" >> /etc/hosts

#Запускаем кластер
sudo systemctl enable glusterd
sudo systemctl start glusterd

#Получаем Ip адрес ноды
NodeIP=$(ip addr  | grep 'inet'| egrep -v '127.0.0.1|inet6' | cut -b 10-22)

#Запускаем добавление узлов кластера только на одном из участников кластера 

if [ $NodeIP == "192.168.10.20" ]; then
  gluster peer probe  node02.local
  gluster peer probe  node03.local
  gluster peer probe  node04.local
  gluster volume create httpd_data replica 3 node0{2,3,4}.local:/opt/gluster-volume force
  echo "=====================ALLL OKKKK======================"
else
  sleep 5
fi

mkdir /var/www
echo "localhost:/httpd_data /var/www glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0" >> /etc/fstab
gluster volume start httpd_data
gluster volume status httpd_data
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
