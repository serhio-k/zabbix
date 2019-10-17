#!/bin/bash
yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm
yum -y install zabbix-agent vim epel-release
systemctl start zabbix-agent
systemctl status zabbix-agent

cat <<EOF2 > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.56.110
ListenPort=10050
StartAgents=3
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF2

sleep 2
systemctl restart zabbix-agent