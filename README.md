# linux-basic-2021_FP
Final project OTUS Linux basic 2021

### Цель: создание отказоустойчевого кластера для веб приложений.

Проект разворачивается на 7 машинах с установленой ОС Centos7 и разделен на 4 блока.

* Блок 1: Frontend-серверы:
  *  Набор из 2 машин node01 (192.168.10.101) и node02 (192.168.10.102)
  *  Скрипт для установки: 1_node_nginx_step1.bash необходимо запустить на всез машинах кластера.
  *  Скрипт устанавливает и настраивает:
  *  nginx: добавление в файл nginx.conf информации о проксировании, добавление файла upstream.conf с указанием адресов backend серверов с веб сервером apache.
  *  pacemaker: контролирует работу двух активных нод nginx, создает виртуальный адрес 192.168.10.100, который динамически перераспределяет в случае отказа одной из нод.
*  Блок 2: Backend-серверы:
  *  Набор из 3 машин node03 (192.168.10.110), node04 (192.168.10.111) и node05 (192.168.10.112)
  *  Скрипты для установки запускаются в следующем порядке: на всех машинах 2_node_httpd_step1.bash, на любой машине из блока 2_node_httpd_step1.1.bash, на всех машинах 2_node_httpd_step2.bash, на любой машине из блока 2_node_httpd_step2.1.bash
  *  Скрипты устанавливает и настраивают:
  *  glusterFS:, node03 и node04 являются активными участниками, а node05 арбитром. ФС монтируется по пути /var/www и финхронизируется с участниками кластера
  *  apache (httpd): на всех участниках блока. 
  *  Производится скачивание и распаковка CMS Wordpress
* Блок 3: BD-серверы:
  *  Набор из 2 машин node06 (192.168.10.121) и node07 (192.168.10.122)
  *  Скрипты для установки запускаются в следующем порядке: на всех машинах 3_node_sql_step1.bash, на любой машине из блока 3_node_sql_step1.1.bash
  *  Скрипты устанавливает и настраивают:
  *  MySQL в режиме MASTER-MASTER, подготавливает БД для установки CMS Wordpress
  *  pacemaker: контролирует работу двух активных нод MySQL, создает виртуальный адрес 192.168.10.120, котрый работает только с одним из активных экземпляров MySQL и динамически перераспределяет его в случае отказа одной из нод.
* Блок 4: серверы мониторинга:
  *  Набор из 1 машины node07 (192.168.10.130)
  *  Скрипт для установки: 4_node_monitoring_step1.bash
  *  Скрипт устанавливает и настраивает:
  *  prometheus со сбором метрик со всех серверов проекта.
  *  grafana
