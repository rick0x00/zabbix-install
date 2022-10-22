#!/usr/bin/env bash

PassRootDB="passrootdb"
PassZABBIXDB="passzabbixdb"

equal="================================================================";

# start define functions

print_help() {
    echo ''
    echo 'Usage:  script.sh [ OPTION ]'   
    echo '  OPTION: (optional)'
    echo '  -h          print this help'
    echo '  -PRDB       Define Password to Root DB'
    echo '  -PZDB       Define Password to zabbiz DB'
    echo ''
}

processing_error() {
    echo "$equal"
    echo ""
    echo "$*"
    echo ""
    echo "$equal"
}

root_check(){
    uid=$(id -u)
    if [ $uid -ne 0 ]; then
        processing_error "Please use ROOT user for run the script."
        exit 1
    fi
}

prepare-workdir(){
    mkdir -p /tmp/workdir/zabbix
    cd /tmp/workdir/zabbix
}

install-zabbix-repo(){
    wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb -O zabbix-release.deb
    dpkg -i zabbix-release.deb
    apt update
}

install-zabbix-server(){
    apt install -y zabbix-server-mysql zabbix-sql-scripts
}

install-zabbix-frontend(){
    apt install -y zabbix-frontend-php zabbix-apache-conf
}

install-zabbix-agent(){
    apt install -y zabbix-agent
}

install-complements(){
    apt install -y mariadb-client mariadb-server
}

create-initial-database(){
    #mysql -uroot -p
    mysql -e "SET PASSWORD FOR 'root'@localhost = PASSWORD('$PassRootDB');"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PassRootDB';"
    mysql -uroot -p"$PassRootDB" -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
    mysql -uroot -p"$PassRootDB" -e "create user zabbix@localhost identified by '$PassZABBIXDB';"
    mysql -uroot -p"$PassRootDB" -e "grant all privileges on zabbix.* to zabbix@localhost;"
    mysql -uroot -p"$PassRootDB" -e "FLUSH PRIVILEGES;"

    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"$PassZABBIXDB" zabbix
}

configure-database-zabbix-server(){
    sed "s/# DBPassword=/DBPassword=$PassZABBIXDB/" /etc/zabbix/zabbix_server.conf > /etc/zabbix/zabbix_server.conf.new

    mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bkp
    mv /etc/zabbix/zabbix_server.conf.new /etc/zabbix/zabbix_server.conf

}

configure-locale(){
    localectl set-locale en_US.UTF-8
}

start-zabbix-and-agent-process(){
    systemctl restart zabbix-server zabbix-agent apache2
    systemctl enable zabbix-server zabbix-agent apache2
}

# end define functions


# start sequence executions

root_check;

# start read CLI Arguments
while [ -n "$1" ]; do
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        print_usage
        exit 0
    elif [ "$1" = "-PRDB" ]; then
        shift
        PassRootDB="$1"
    elif [ "$1" = "-PZDB" ]; then
        shift
        PassZABBIXDB="$1"
    fi
    shift
done
# end read CLI Arguments

prepare-workdir;
install-zabbix-repo;
install-zabbix-server;
install-zabbix-frontend;
install-zabbix-agent;
install-complements;
create-initial-database;
configure-database-zabbix-server;
configure-locale;
start-zabbix-and-agent-process;

# start sequence executions