#!/bin/bash

#Запускаем добавление узлов кластера только на одном из участников кластера 
gluster peer probe  node02.local
gluster peer probe  node03.local
gluster peer probe  node04.local
sleep 3
gluster volume create httpd_data replica 3 node0{2,3,4}.local:/opt/gluster-volume force