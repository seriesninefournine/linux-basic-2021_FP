#!/bin/bash

gluster volume start httpd_data
mkdir /var/www

echo "[Unit]
Description=gluster mount
[Mount]
What=localhost:/httpd_data
Where=/var/www
Type=glusterfs
Options=defaults,_netdev,backupvolfile-server=localhost" > /etc/systemd/system/mnt-gluster.mount

echo "[Unit]
Description=gluster mount
Requires=network-online.target
[Automount]
Where=/var/www
TimeoutIdleSec=301
[Install]
WantedBy=remote-fs.target" > /etc/systemd/system/mnt-gluster.automount

chmod +x /etc/systemd/system/mnt-gluster.*
systemctl enable mnt-gluster.automount
systemctl start mnt-gluster.automount
