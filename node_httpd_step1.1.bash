#!/bin/bash

#Запускаем добавление узлов кластера только на одном из участников кластера 
gluster peer probe  node03.local
gluster peer probe  node04.local
gluster peer probe  node05.local
sleep 3
gluster volume create httpd_data replica 2 arbiter 1 node0{3,4,5}.local:/opt/gluster-volume force
