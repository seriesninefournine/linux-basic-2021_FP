#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release
yum -y install ntp ntpdate nginx pcs pacemaker fence-agents-all
systemctl enable ntpd pacemaker pcsd corosync
systemctl start ntpd
ntpdate -s ntp.ubuntu.com
sleep 15

#Настраиваем pacemaker
echo 'pacpass' | passwd --stdin hacluster

#добавляем адреса узлов кластера
echo "
192.168.10.101 node01.local 
192.168.10.102 node02.local" >> /etc/hosts

curl -O https://raw.githubusercontent.com/seriesninefournine/linux-basic-2021_FP/main/node_nginx_cfg/nginx.conf
curl -O https://raw.githubusercontent.com/seriesninefournine/linux-basic-2021_FP/main/node_nginx_cfg/upstream.conf
mv -f ./nginx.conf /etc/nginx/nginx.conf
mv -f ./upstream.conf /etc/nginx/conf.d/upstream.conf

systemctl start pcsd 