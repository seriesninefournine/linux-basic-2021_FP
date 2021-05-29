#!/bin/bash

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