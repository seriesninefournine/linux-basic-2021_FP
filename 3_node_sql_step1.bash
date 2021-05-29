#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
yum -y install wget nano epel-release mysql-server expect pcs pacemaker fence-agents-all
yum -y install ntp ntpdate 
systemctl enable ntpd 
systemctl disable mysqld
systemctl start ntpd
ntpdate -s ru.pool.ntp.org
sleep 15

#добавляем адреса узлов 
echo "
192.168.10.121 node06.local 
192.168.10.122 node07.local" >> /etc/hosts

#Запускаем pacemaker
echo 'pacpass' | passwd --stdin hacluster
systemctl enable pcsd 
systemctl start pcsd 

#Настраиваем MySQL
echo 'bind-address            = 0.0.0.0
gtid_mode=ON
enforce_gtid_consistency=ON' >> /etc/my.cnf

systemctl start mysqld
MYSQL_PASS='Qq123456!'
#Автомтизируем mysql_secure_installation

MYSQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | grep -oE '[^ ]+$')

/usr/bin/expect<<EXP_SCRIPT
set timeout 10
spawn mysql_secure_installation
match_max 100000
expect -exact "Enter password for user root: "
send -- "$MYSQL_TMP_PASS\r"
expect -exact "New password: "
send -- "$MYSQL_PASS\r"
expect -exact "Re-enter new password: "
send -- "$MYSQL_PASS\r"
expect -exact "Change the password for root ? ((Press y|Y for Yes, any other key for No) : "
send -- "n\r"
expect -exact "Remove anonymous users? (Press y|Y for Yes, any other key for No) : "
send -- "y\r"
expect -exact "Disallow root login remotely? (Press y|Y for Yes, any other key for No) : "
send -- "y\r"
expect -exact "Remove test database and access to it? (Press y|Y for Yes, any other key for No) : "
send -- "y\r"
expect -exact "Reload privilege tables now? (Press y|Y for Yes, any other key for No) : "
send -- "y\r"
expect eof
EXP_SCRIPT


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
