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




if [ $(hostname) == node06.local ]; then
  echo 'server_id = 1' >> /etc/my.cnf
  systemctl restart mysqld
  mysql -u 'root' -p$MYSQL_PASS -e "create user 'replicator07'@'%' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_PASS'; GRANT SELECT, SHOW VIEW, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator07'@'%'; flush privileges;"
  mysql -u 'root' -p$MYSQL_PASS -e "STOP SLAVE;"
  mysql -u 'root' -p$MYSQL_PASS -e "CHANGE MASTER TO MASTER_HOST='node07.local', MASTER_USER='replicator06', MASTER_PASSWORD='$MYSQL_PASS', GET_MASTER_PUBLIC_KEY = 1, MASTER_AUTO_POSITION=1;"
  mysql -u 'root' -p$MYSQL_PASS -e "START SLAVE;"
  systemctl stop mysqld
fi
	
if [ $(hostname) == node07.local ]; then
  echo 'server_id = 2' >> /etc/my.cnf
  systemctl restart mysqld
  mysql -u 'root' -p$MYSQL_PASS -e "create user 'replicator06'@'%' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_PASS'; GRANT SELECT, SHOW VIEW, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator06'@'%'; flush privileges;"
  mysql -u 'root' -p$MYSQL_PASS -e "STOP SLAVE;"
  mysql -u 'root' -p$MYSQL_PASS -e "CHANGE MASTER TO MASTER_HOST='node06.local', MASTER_USER='replicator07', MASTER_PASSWORD='$MYSQL_PASS', GET_MASTER_PUBLIC_KEY = 1, MASTER_AUTO_POSITION=1;"
  mysql -u 'root' -p$MYSQL_PASS -e "START SLAVE;"
  mysql -u 'root' -p$MYSQL_PASS -e "create user 'root'@'%' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_PASS'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; flush privileges;"
  mysql -u 'root' -p$MYSQL_PASS -e "CREATE DATABASE wordpress;"
  systemctl stop mysqld
  
  #Настраиваем pacemaker
  pcs cluster auth node06.local node07.local -u hacluster -p 'pacpass'
  pcs cluster setup --name mysql_cl node06.local node07.local
  pcs cluster start --all
  pcs cluster enable --all
  pcs property set stonith-enabled=false
  pcs property set no-quorum-policy=ignore
  pcs resource create virtualip ocf:heartbeat:IPaddr2 ip="192.168.10.120" cidr_netmask="24" op monitor interval="10s"
  pcs resource create mysql_service01 ocf:heartbeat:mysql binary="/usr/sbin/mysqld" config="/etc/my.cnf" datadir="/var/lib/mysql" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" op start timeout=20s op stop timeout=20s op monitor interval=20s timeout=30s
  pcs resource clone mysql_service01
  pcs constraint colocation add virtualip with mysql_service01-clone INFINITY
  pcs constraint order mysql_service01-clone then virtualip
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
