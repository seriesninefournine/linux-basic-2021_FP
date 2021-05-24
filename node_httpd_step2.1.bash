#!/bin/bash

wget https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
tar -xzf glpi-9.5.5.tgz
cd ./glpi
mv ./* /var/www/html/

chown -R apache:apache /var/www
