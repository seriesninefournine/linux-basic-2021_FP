#!/bin/bash

#Запускаем синхронизацию и создаем файловую систему
drbdadm primary --force r0
mkfs -t ext4 /dev/drbd1

#Настраиваем pacemaker
pcs cluster auth node06.local node07.local -u hacluster -p 'pacpass'
pcs cluster setup --name drbd_cls node01.local node02.local
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
pcs resource create virtualip ocf:heartbeat:IPaddr2 ip="192.168.10.120" cidr_netmask="24" clusterip_hash="sourceip-sourceport" op monitor interval="10s"
pcs resource enable virtualip

pcs resource create nginx ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor interval=5s timeout=5s
pcs resource clone nginx
pcs constraint colocation add virtualip with nginx-clone
pcs constraint order start nginx-clone then start virtualip

#настраиваем mysql
echo 'bind-address            = 0.0.0.0' >> /etc/my.cnf

systemctl start mysqld

#Вытаскиваем временный пароль от MySQL и готовим новый
MYSQL_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | grep -oE '[^ ]+$')
MYSQL_PASS='Qq123456!'

#Проводим первоначальную настройку БД
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

