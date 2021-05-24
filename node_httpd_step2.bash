#!/bin/bash

gluster volume start httpd_data
mkdir /mnt/gluster
echo 'localhost:/httpd_data /mnt/gluster glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
mount -a

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
systemctl enable mnt-gluster.automount
systemctl start mnt-gluster.automount

systemctl start docker
docker run -it -d -p 80:80 --name httpd-apache -v /mnt/gluster:/var/www/html php:7.2-apache
