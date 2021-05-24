#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release centos-release-gluster6 yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install ntp ntpdate glusterfs-server docker-ce docker-ce-cli containerd.io
systemctl enable ntpd docker
systemctl start ntpd
ntpdate -s ru.pool.ntp.org
sleep 15

#добавляем адреса узлов кластера
echo "
192.168.10.110 node03.local 
192.168.10.111 node04.local 
192.168.10.112 node05.local" >> /etc/hosts

#Запускаем кластер
mkdir /opt/gluster-volume
sudo systemctl enable glusterd
sudo systemctl start glusterd