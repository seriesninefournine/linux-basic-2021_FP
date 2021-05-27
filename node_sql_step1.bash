#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
yum -y install nano epel-release mysql-server expect pcs pacemaker fence-agents-all
yum -y install ntp ntpdate 
systemctl enable ntpd pacemaker pcsd corosync 
systemctl disable mysqld
systemctl start ntpd
ntpdate -s ru.pool.ntp.org
sleep 15

#добавляем адреса узлов кластера
echo "
192.168.10.121 node06.local 
192.168.10.122 node07.local" >> /etc/hosts

#Настраиваем pacemaker
echo 'pacpass' | passwd --stdin hacluster
systemctl start pcsd 
