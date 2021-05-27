#!/bin/bash

pcs cluster auth node01.local node02.local -u hacluster -p 'pacpass'
pcs cluster setup --name hginx_clus node01.local node02.local
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
pcs resource create virtualip ocf:heartbeat:IPaddr2 ip="192.168.10.100" cidr_netmask="24" clusterip_hash="sourceip-sourceport" op monitor interval="10s"
pcs resource enable virtualip
#### pcs constraint colocation add virtualip ag_cluster-master INFINITY with-rsc-role=Master
#### pcs resource move virtualip node02.local
pcs resource create nginx ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor interval=5s timeout=5s
pcs resource clone nginx
pcs constraint colocation add virtualip with nginx-clone
pcs constraint order start nginx-clone then start virtualip