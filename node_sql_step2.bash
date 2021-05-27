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
fi
	
if [ $(hostname) == node07.local ]; then
  echo 'server_id = 2' >> /etc/my.cnf
  systemctl restart mysqld
  mysql -u 'root' -p$MYSQL_PASS -e "create user 'replicator06'@'%' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_PASS'; GRANT SELECT, SHOW VIEW, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator06'@'%'; flush privileges;"
  mysql -u 'root' -p$MYSQL_PASS -e "STOP SLAVE;"
  mysql -u 'root' -p$MYSQL_PASS -e "CHANGE MASTER TO MASTER_HOST='node06.local', MASTER_USER='replicator07', MASTER_PASSWORD='$MYSQL_PASS', GET_MASTER_PUBLIC_KEY = 1, MASTER_AUTO_POSITION=1;"
  mysql -u 'root' -p$MYSQL_PASS -e "START SLAVE;"
fi
