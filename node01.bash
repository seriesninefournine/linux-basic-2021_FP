#!/bin/bash

#Отключаем то, что может нам мешать
setenforce 0
systemctl stop firewalld

#Устанавливаем нужное ПО
yum -y install nano epel-release
yum -y install ntp ntpdate nginx git
systemctl enable ntpd nginx
systemctl start ntpd
ntpdate -s ntp.ubuntu.com
sleep 15

#Генерируем ключи для git
ssh-keygen -P "" -f /root/.ssh/id_rsa

echo '-------rsa key begin-------'
cat /root/.ssh/id_rsa.pub
echo '--------rsa key end--------'
read -p "Нажмите любую кнопку для продолжения скрипта"

#скачиваем и помещаем в нужные директории конфигурационные файлы nginx
mkdir nginx_cfg
cd ./nginx_cfg

git clone git@github.com:seriesninefournine/linux-basic-2021_FP.git
mv ./linux-basic-2021_FP/node01cfg/nginx.conf /etc/nginx/
mv ./linux-basic-2021_FP/node01cfg/upstream.conf /etc/nginx/conf.d/

systemctl start nginx
