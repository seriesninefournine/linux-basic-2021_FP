#!/bin/bash

gluster volume start httpd_data
mkdir /mnt/gluster

echo "[Unit]
Description=gluster mount
[Mount]
What=localhost:/httpd_data
Where=/mnt/gluster
Type=glusterfs
Options=defaults,_netdev,backupvolfile-server=localhost" > /etc/systemd/system/mnt-gluster.mount

echo "[Unit]
Description=gluster mount
Requires=network-online.target
[Automount]
Where=/mnt/gluster
TimeoutIdleSec=301
[Install]
WantedBy=remote-fs.target" > /etc/systemd/system/mnt-gluster.automount

chmod +x /etc/systemd/system/mnt-gluster.*
systemctl start mnt-gluster.automount

#Устанавливаем httpd + php с необходимыми модулями
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --disable remi-safe
yum-config-manager --enable remi
yum-config-manager --enable remi-php74

yum -y install httpd php74
