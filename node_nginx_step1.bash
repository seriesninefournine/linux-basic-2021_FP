#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release
yum -y install wget ntp ntpdate nginx pcs pacemaker fence-agents-all
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

if [ $(hostname) == node01.local ]; then
  pcs cluster auth node01.local node02.local -u hacluster -p 'pacpass'
  pcs cluster setup --name hginx_clus node01.local node02.local
  pcs property set stonith-enabled=false
  pcs property set no-quorum-policy=ignore
  pcs resource create virtualip ocf:heartbeat:IPaddr2 ip="192.168.10.100" cidr_netmask="24" clusterip_hash="sourceip-sourceport" op monitor interval="10s"
  pcs resource create nginx ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor interval=5s timeout=5s
  pcs resource clone nginx
  pcs constraint colocation add virtualip with nginx-clone
  pcs constraint order start nginx-clone then start virtualip
  pcs cluster enable --all
  pcs cluster start --all
fi

systemctl enable pacemaker corosync 

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
