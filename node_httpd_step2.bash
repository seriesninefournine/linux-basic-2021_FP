#!/bin/bash

#Добавляем узлы кластера в пул
gluster peer probe  node02.local
gluster peer probe  node03.local
gluster peer probe  node04.local
