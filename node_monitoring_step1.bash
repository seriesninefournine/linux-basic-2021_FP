#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

#Устанавливаем нужное ПО
yum -y install wget nano ntp ntpdate rsync
systemctl enable ntpd 
systemctl start ntpd
ntpdate -s ru.pool.ntp.org
sleep 15

#Устанавливаем и настраиваем prometheus
useradd -M -s /usr/sbin/nologin prometheus
mkdir /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus /var/lib/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.26.0/prometheus-2.26.0.linux-amd64.tar.gz
tar -xzf prometheus-2.26.0.linux-amd64.tar.gz
cp ./prometheus-2.26.0.linux-amd64/prometheus /usr/local/bin/
cp ./prometheus-2.26.0.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cd ./prometheus-2.26.0.linux-amd64/
cp -r ./console_libraries /etc/prometheus
cp -r ./consoles /etc/prometheus
cp ./prometheus.yml /etc/prometheus
cd ..
chown -R prometheus:prometheus /etc/prometheus
echo "[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/bin/kill -HUP $MAINPID
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/prometheus.service

echo "
  - job_name: 'MySQL'
    scrape_interval: 5s
    static_configs:
    - targets: ['192.168.10.121:9100', '192.168.10.122:9100']
  - job_name: 'nginx'
    scrape_interval: 5s
    static_configs:
    - targets: ['192.168.10.101:9100', '192.168.10.102:9100']
  - job_name: 'httpd'
    scrape_interval: 5s
    static_configs:
    - targets: ['192.168.10.110:9100', '192.168.10.111:9100', '192.168.10.112:9100']	
" >> /etc/prometheus/prometheus.yml

#Устанавливаем grafana
wget --no-check-certificate https://dl.grafana.com/oss/release/grafana-7.5.5-1.x86_64.rpm
yum install -y ./grafana-7.5.5-1.x86_64.rpm

systemctl daemon-reload
systemctl enable prometheus grafana-server
systemctl start prometheus grafana-server

#настраиваем rsync
mkdir /backups

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