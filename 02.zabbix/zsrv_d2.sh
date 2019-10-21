#!/bin/bash

yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

LOCIP='192.168.56.110'

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

systemctl enable zabbix-server zabbix-agent
systemctl start zabbix-server zabbix-agent
systemctl start httpd
systemctl enable httpd
sleep 3

sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/usr\/share\/zabbix"/g' /etc/httpd/conf/httpd.conf
systemctl restart zabbix-server
systemctl restart httpd

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

JavaGateway=$LOCIP
JavaGatewayPort=10052
StartJavaPollers=5

EOF

systemctl stop zabbix-server
sleep 2
cp /vagrant/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php


systemctl start zabbix-server

yum -y install zabbix-java-gateway

systemctl start zabbix-java-gateway
systemctl enable zabbix-java-gateway
yum -y install zabbix-get


