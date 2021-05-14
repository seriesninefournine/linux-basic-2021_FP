#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
systemctl stop firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release centos-release-gluster6
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
  #Добавляем узлы кластера в пул
  gluster peer probe  node02.local
  gluster peer probe  node03.local
  gluster peer probe  node04.local

  #Запускаем кластер
  #gluster volume create httpd_data replica 3 node0{2,3,4}.local:/opt/gluster-volume force
fi

gluster volume create httpd_data replica 3 $HOSTNAME:/opt/gluster-volume force
