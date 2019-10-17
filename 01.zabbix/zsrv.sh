#!/bin/bash

yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

#DB+agent
yum install -y mariadb mariadb-server vim net-tools zabbix-agent
/usr/bin/mysql_install_db --user=mysql
systemctl enable mariadb
systemctl start mariadb

mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin"
mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'xpa55w0rd'"

#Zabbix
yum install -y zabbix-server-mysql zabbix-web-mysql
zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -uzabbix -pxpa55w0rd zabbix
echo "DBHost=localhost" >> /etc/zabbix/zabbix_server.conf
echo "DBPassword=xpa55w0rd" >> /etc/zabbix/zabbix_server.conf
sed -i 's-# php_value date.timezone Europe/Riga-php_value date.timezone Europe/Minsk-' /etc/httpd/conf.d/zabbix.conf

systemctl enable zabbix-server
systemctl start zabbix-server
systemctl start httpd
sleep 3

sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/usr\/share\/zabbix"/g' /etc/httpd/conf/httpd.conf
systemctl restart zabbix-server
systemctl restart httpd
systemctl start zabbix-agent
systemctl status zabbix-agent

cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
SocketDir=/var/run/zabbix
DBName=zabbix
DBUser=zabbix
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
StatsAllowedIP=127.0.0.1
DBHost=localhost
DBPassword=xpa55w0rd
EOF

cat <<EOF2 > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=127.0.0.1
ListenPort=10050
ListenIP=0.0.0.0
StartAgents=3
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF2

systemctl restart zabbix-agent
systemctl restart zabbix-server