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
192.168.10.24 node04.local" >> /etc/hosts

#Подготавливаем раздел для хранения данных кластера
mkdir /opt/gluster

#Запускаем кластер
sudo systemctl enable glusterd
sudo systemctl start glusterd
