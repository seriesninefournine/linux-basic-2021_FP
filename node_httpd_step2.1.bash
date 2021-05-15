#!/bin/bash

yum -y install wget
mkdir ./glpi
cd ./glpi
wget --no-check-certificate https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz
tar -xzf glpi-9.5.5.tgz
cd ./glpi

