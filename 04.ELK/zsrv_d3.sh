#!/bin/bash
#elastic SERVER
yum -y install epel-release vim net-tools wget

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOFEL > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOFEL

yum -y install elasticsearch
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl status elasticsearch

#kibana
cat <<EOFKI >/etc/yum.repos.d/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOFKI

yum -y install kibana

systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
systemctl status kibana.service

#Setting elasticsearch
echo "network.host: 192.168.56.110" >> /etc/elasticsearch/elasticsearch.yml
echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml
echo "action.auto_create_index: .monitoring*,.watches,.triggered_watches,.watcher-history*,.ml*" >> /etc/elasticsearch/elasticsearch.yml
echo "transport.host: localhost" >> /etc/elasticsearch/elasticsearch.yml

systemctl restart elasticsearch

#Setting kibana
cat <<EOF3 > /etc/kibana/kibana.yml
server.port: 5601
server.host: "192.168.56.110"
elasticsearch.hosts: ["http://192.168.56.110:9200"]
server.ssl.enabled: false
EOF3

systemctl restart kibana.service