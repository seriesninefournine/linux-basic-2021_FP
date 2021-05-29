#!/bin/bash

  #Настраиваем pacemaker
  pcs cluster auth node06.local node07.local -u hacluster -p 'pacpass'
  pcs cluster setup --name mysql_cl node06.local node07.local
  pcs cluster start --all
  pcs cluster enable --all
  pcs property set stonith-enabled=false
  pcs property set no-quorum-policy=ignore
  pcs resource create virtualip ocf:heartbeat:IPaddr2 ip="192.168.10.120" cidr_netmask="24" op monitor interval="10s"
  pcs resource create mysql_service01 ocf:heartbeat:mysql binary="/usr/sbin/mysqld" config="/etc/my.cnf" datadir="/var/lib/mysql" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" op start timeout=20s op stop timeout=20s op monitor interval=20s timeout=30s
  pcs resource clone mysql_service01
  pcs constraint colocation add virtualip with mysql_service01-clone INFINITY
  pcs constraint order mysql_service01-clone then virtualip
