#!/bin/bash
yum install -y epel-release vim java-1.8.0-openjdk.x86_64 wget tomcat tomcat-webapps tomcat-admin-webapps
systemctl start tomcat
systemctl enable tomcat
systemctl status tomcat

cp /vagrant/SampleWebApp.war /usr/share/tomcat/webapps/
systemctl restart tomcat
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF > /etc/yum.repos.d/logstash.repo
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum -y install logstash
systemctl start logstash
systemctl enable logstash
systemctl status logstash

chmod -R 755 /var/log/

cat <<EOF2 > /etc/logstash/conf.d/tom2.conf
input {
  file {
    path => "/var/log/tomcat/*.log"
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => ["192.168.56.110:9200"]
  }
  stdout { codec => rubydebug }
}
EOF2

systemctl restart logstash