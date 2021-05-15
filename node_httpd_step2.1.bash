#!/bin/bash

yum -y install wget
wget https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
tar -xzf glpi-9.5.5.tgz
cd ./glpi

echo -e "
<VirtualHost *:8080>
ServerAdmin web@master.local
DocumentRoot /mnt/gluster
</VirtualHost>" > /etc/httpd/conf.d/glpi.conf

mv ./* /mnt/gluster
chown -R apache:apache /mnt/gluster
systemctl start httpd