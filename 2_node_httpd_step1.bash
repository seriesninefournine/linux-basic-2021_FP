#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
yum -y install wget nano epel-release centos-release-gluster6 yum-utils
yum -y install ntp ntpdate glusterfs-server
systemctl enable ntpd 
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

#Устанавливаем и настраиваем node_exporter
useradd -M -s /usr/sbin/nologin node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
tar -xzf node_exporter-1.1.2.linux-amd64.tar.gz
cp ./node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

echo "[Unit] 
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter