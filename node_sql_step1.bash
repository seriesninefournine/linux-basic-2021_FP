#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
rpm -Uvh https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
yum -y install nano epel-release kmod-drbd84 drbd84-utils mysql-server expect pcs pacemaker fence-agents-all
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

#Создаем раздел для DRDB и форматируем его
#fdisk /dev/sdb <<EEOF
#n
#p
#1
#2048
#16777215
#w
#EEOF

#Создаем конфигурацию BRDB и инициализируем метаданные
mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig
echo "global {
 usage-count  yes;
}
common {
 net {
  protocol C;
 }
}" > /etc/drbd.d/global_common.conf

echo "resource r0 {
  on node06.local {
    device /dev/drbd1;
    disk /dev/sdb;
    address 192.168.10.121:7789;
    meta-disk internal;
  }
  on node07.local {
    device /dev/drbd1;
    disk /dev/sdb;
    address 192.168.10.122:7789;
    meta-disk internal;
  }
}" > /etc/drbd.d/r0.res

drbdadm create-md r0 <<EEOF
yes
EEOF

#Запускаем ресурс
drbdadm up r0

modprobe drbd
echo drbd > /etc/modules-load.d/drbd.conf

#Настраиваем pacemaker
echo 'pacpass' | passwd --stdin hacluster
systemctl enable 
systemctl start pcsd 

