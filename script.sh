#!/bin/bash

PassRootDB="passrootdb"
PassZABBIXDB="passzabbixdb"

mkdir -p /tmp/workdir/zabbix
cd /tmp/workdir/zabbix

wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb -O zabbix-release.deb
dpkg -i zabbix-release.deb
apt update

apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

apt install mariadb-client mariadb-server

#mysql -uroot -p
mysql -e "SET PASSWORD FOR 'root'@localhost = PASSWORD("$PassRootDB");"
mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -e "create user zabbix@localhost identified by '$PassZABBIXDB';"
mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
mysql -e "FLUSH PRIVILEGES;"

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"$PassRootDB" zabbix

nano /etc/zabbix/zabbix_server.conf
echo "DBPassword=$PassZABBIXDB"

locale-gen "en_US.UTF-8"

systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2
