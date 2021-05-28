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

if [ $(hostname) == node03.local ]; then
  wget http://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cd ./wordpress
  mv ./* /var/www/html/
  chown -R apache:apache /var/www
  
  yum -y install rsync sshpass
  
  echo "
    pid file = /var/run/rsyncd.pid
    lock file = /var/run/rsync.lock
    log file = /var/log/rsync.log
    [share]
    path = /backups
    hosts allow = 192.168.10.*
    hosts deny = *
    list = true
    uid = root
    gid = root
    read only = false" >> /etc/rsyncd.conf
	
	
  echo '
  [Unit]
  Description=A program for synchronizing files over a network
  After=syslog.target network.target
  ConditionPathExists=/etc/rsyncd.conf
  
  [Service]
  EnvironmentFile=-/etc/sysconfig/rsyncd
  ExecStart=/usr/bin/rsync --daemon --no-detach "$OPTIONS"
  
  [Install]
  WantedBy=multi-user.target' > /usr/lib/systemd/system/rsyncd.service
  systemctl daemon-reload
  systemctl enable rsyncd
  systemctl start rsyncd
  ssh-keygen -f ~/.ssh/id_rsa -q -P ""
  sshpass -p 'node08adm' ssh-copy-id -i ~/.ssh/id_rsa root@192.168.10.130
  
  
  echo 'rsync -az -delete -e "ssh -p 22" /var/www root@192.168.10.130:/backups/$(date +"%y-%m-%d")' > $(pwd)/backup.bash && chmod +x $(pwd)/backup.bash
  crontab -l > mycron
  echo "13 * * * * $(pwd)/backup.bash" > mycron
  crontab mycron
  rm -f mycron

fi

