#!/bin/bash

yum -y install wget
wget https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
tar -xzf glpi-9.5.5.tgz
cd ./glpi
mv -r ./* /var/www/html/ -f
chown -R apache:apache /var/www
