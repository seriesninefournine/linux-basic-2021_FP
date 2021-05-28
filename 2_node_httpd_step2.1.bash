#!/bin/bash

#Устанавливаем CMS
  wget http://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cd ./wordpress
  mv ./* /var/www/html/
  chown -R apache:apache /var/www
 
#Устанавливаем и настраиваем rsync 
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
