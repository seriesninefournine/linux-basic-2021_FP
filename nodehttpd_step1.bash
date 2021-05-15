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