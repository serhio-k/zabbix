#!/bin/bash
yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm
yum install -y epel-release vim jq zabbix-agent java-1.8.0-openjdk.x86_64 wget tomcat tomcat-webapps tomcat-admin-webapps
systemctl start zabbix-agent tomcat
systemctl enable zabbix-agent tomcat
systemctl status zabbix-agent tomcat

#VARS
OPT='-X POST http://192.168.56.110/zabbix/api_jsonrpc.php'
HOST='zagent'
LOCIP='192.168.56.111'
SRV='192.168.56.110'
ZB_USER='Admin'
ZB_PASS='zabbix'
ZB_GROUP='CloudHosts'
ZB_TEMPLNAME='ZBX01'

cat <<EOF > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$SRV
ListenPort=10050
#StartAgents=3
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Hostname=$HOST
ServerActive=$SRV
EOF

sleep 2
systemctl restart zabbix-agent

#Install sender
yum -y install zabbix-sender
#zabbix_sender -z $SRV -s "zagent" -k dba -o test_send_message

cat << EOFTC >> /etc/tomcat/tomcat.conf
JAVA_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=$LOCIP -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.rmi.port=12346 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
EOFTC
systemctl restart tomcat

cp /vagrant/tomcat-catalina-jmx-remote-7.0.76.jar /usr/share/tomcat/lib/
cp /vagrant/SampleWebApp.war /usr/share/tomcat/webapps/

systemctl restart tomcat

################
###ZABBIX API###
################

#GET AUTH KEY
ZB_AUTHKEY=`curl -d  "{\"params\": {\"password\": \"$ZB_PASS\", \"user\": \"$ZB_USER\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\",\"id\": 1}" -H "Content-Type: application/json-rpc" $OPT | jq -r ".result"`

#Create host
ZB_HOSTGRP=`curl -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.create\",\"params\":{\"name\": \"$ZB_GROUP\"},\"auth\":\"$ZB_AUTHKEY\",\"id\":0}" -H "Content-Type: application/json-rpc" $OPT | jq -r ".result.groupids[]"`

#Create template
ZB_TEMPLATEID=`curl -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.create\",\"params\":{\"host\": \"$ZB_TEMPLNAME\", \"groups\":{\"groupid\":\"$ZB_HOSTGRP\"}},\"auth\":\"$ZB_AUTHKEY\",\"id\":0}" -H "Content-Type: application/json-rpc" $OPT | jq -r ".result.templateids[]"`

#Create host
curl -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{\"host\": \"$HOST\", \"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"$LOCIP\",\"dns\":\"\",\"port\":\"10050\"}],\"groups\":[{\"groupid\":\"$ZB_HOSTGRP\"}],\"templates\":[{\"templateid\":\"$ZB_TEMPLATEID\"}]},\"auth\":\"$ZB_AUTHKEY\",\"id\":1}" -H "Content-Type: application/json-rpc" $OPT


#Check
echo "Group:" $ZB_GROUP "id:" $ZB_HOSTGRP
echo "Template:" $ZB_TEMPLNAME "id:" $ZB_TEMPLATEID
echo "Agent:" $HOST