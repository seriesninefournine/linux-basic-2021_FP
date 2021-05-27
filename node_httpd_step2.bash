#!/bin/bash

gluster volume start httpd_data
mkdir /var/www

echo "[Unit]
Description=gluster mount
[Mount]
What=localhost:/httpd_data
Where=/var/www
Type=glusterfs
Options=defaults,_netdev,backupvolfile-server=localhost" > /etc/systemd/system/var-www.mount

echo "[Unit]
Description=gluster mount
Requires=network-online.target
[Automount]
Where=/var/www
[Install]
WantedBy=remote-fs.target" > /etc/systemd/system/var-www.automount


chmod +x /etc/systemd/system/var-www.*
systemctl daemon-reload
systemctl enable var-www.automount
systemctl start var-www.automount

#Устанавливаем httpd + php с необходимыми модулями
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --disable remi-safe
yum-config-manager --enable remi
yum-config-manager --enable remi-php74

yum -y install httpd
yum -y install php php-mysqli php-mbstring php-gd php-simplexml php-intl php-ldap php-apcu php-pecl-zendopcache php-xmlrpc php-pear-CAS php-zip

systemctl enable httpd
systemctl start httpd