#!/bin/bash
##---------- Author : SKYRIM D/X ------------------------------------------------------------##
##---------- Github page : https://github.com/alexdu828/linux-shell-script-------------------##
##---------- Tested on : ubuntu 20.04 LTS----------------------------------------------------##
##---------- Updated version : v0.1 (Updated on  2023年03月16 -------------------------------##
##-----NOTE: This script requires root privileges, otherwise one could run the script -------##
##---- as a sudo user who got root privileges. ----------------------------------------------##
##----------- "sudo /bin/bash <ScriptName>" -------------------------------------------------##

#variables
zbx_db01=10.10.60.112
zbx_db02=10.10.60.113
#begin



###########################################Memo################################################
## Ubuntu Server模板制作,需要联网
###############################################################################################

## 替换Ubuntu源为中科大源
sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
sudo apt-get updated

## 配置PostgreSQL APT源(此源包括pgbouncer)
wget --quiet -O - https://mirrors.ustc.edu.cn/postgresql/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb https://mirrors.ustc.edu.cn/postgresql/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

## 配置TimescaleDB APT源
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list


## 配置Zabbix APT源 ,建议版本为6.3,
## 不采用最新版本的原因是Zabbix与Grafana 9.3插件的兼容性,主要是出现Invalid params. Invalid parameter "/": unexpected parameter "user".错误,https://github.com/alexanderzobnin/grafana-zabbix ISSUS:#1583
## Grafana	Zabbix	Grafana-Zabbix Plugin
##  9.4.3	6.4.0	4.2.10
# wget https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1%2Bubuntu20.04_all.deb
wget https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/6.3/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.3-3%2Bubuntu20.04_all.deb
sudo sed -i 's/repo.zabbix.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

## 配置Zabbix 相关依赖包
sudo apt-get install ttf-wqy-microhei nmap language-pack-zh-hans  -y
sudo apt-get upgrade -y

# 配置中文显示环境
sudo sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
sudo locale-gen 
sudo sed -i 's/en_US/zh_CN/g' /etc/default/locale 
###############################################################################################

# 配置时间同步,根据实际情况修改
sudo echo "NTP=10.10.20.103" >>/etc/systemd/timesyncd.conf
systemctl restart systemd-timesyncd


###########################################Memo################################################
## 数据库群集与负载均衡环境配置,需要联网
## PGSQLDB+TIMEScaleDB节点,采用Streaming Replication+PgBouncer轻量级中间件实现高可用,2台HAProxy+keepalive节点
## 关于PgBouncer与Pgpool-II的对比，参考：https://dzone.com/articles/postgresql-connection-pooling-part-4-pgbouncer-vs#:~:text=The%20bottom%20line%20-%20Pgpool-II%20is%20a%20great,and%20reduce%20resource%20consumption%2C%20PgBouncer%20wins%20hands%20down.
###############################################################################################

# 所有PGSQLDB节点安装
sudo apt -y install postgresql-14
## 修改PGSQLDB数据存储目录,目录为/pgdata/
chown -R postgres:postgres /pgdata
chmod 750 -R /pgdata
sudo sed -i 's/var\/lib\/postgresql\/14\/main/pgdata\/data/g'  /etc/postgresql/14/main/postgresql.conf
sudo -u postgres /usr/lib/postgresql/14/bin/initdb -D /pgdata/data   
sudo systemctl restart postgresql
sudo -u postgres psql 
show data_directory;
# postgres=# show data_directory;
#  data_directory
# ----------------
#  /pgdata/data
# (1 行记录)

# 配置TIMEScaleDB,参考：https://docs.timescale.com/install/latest/self-hosted/installation-linux/
sudo apt install -y timescaledb-2-postgresql-14
## 自动调整postgresql配置参数 
sudo timescaledb-tune --quiet
systemctl restart postgresql

# 配置Streaming Replication

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '$zbx_db01'/g" /etc/postgresql/14/main/postgresql.conf
sudo sed -i 's/#wal_level/wal_level/g' /etc/postgresql/14/main/postgresql.conf
sudo sed -i 's/#max_wal_senders/max_wal_senders/g' /etc/postgresql/14/main/postgresql.conf
sudo sed -i 's/#wal_keep_size = 0/wal_keep_size = 1GB/g' /etc/postgresql/14/main/postgresql.conf
sudo sed -i 's/#wal_compression = off/wal_compression = on/g' /etc/postgresql/14/main/postgresql.conf
sudo sed -i 's/#synchronous_commit = on/synchronous_commit = on/g' /etc/postgresql/14/main/postgresql.conf


# host replication [replication user] [allowed network] [authentication method]
# echo "host    all             all             0.0.0.0/0             md5">>/etc/postgresql/14/main/pg_hba.conf                 #允许所有网络访问
echo "host    replication     rep_user        10.10.60.112/32            md5" >>/etc/postgresql/14/main/pg_hba.conf
echo "host    replication     rep_user        10.10.60.113/32            md5" >>/etc/postgresql/14/main/pg_hba.conf

# 创建rep_user用户
su postgres 
createuser --replication -P rep_user
systemctl restart postgresql

# 备节点操作
#variables
zbx_db01=10.10.60.112
zbx_db02=10.10.60.113
#begin
systemctl stop postgresql
rm -rf /pgdata/data/*
sudo -u postgres pg_basebackup -R  -h $zbx_db01 -U rep_user -v -D /pgdata/data/ -P 
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '$zbx_db02'/g" /etc/postgresql/14/main/postgresql.conf
sudo sed -i "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/14/main/postgresql.conf
systemctl start postgresql
# 主节点检查

sudo -U postgres psql 
select usename, application_name, client_addr, state, sync_priority, sync_state from pg_stat_replication;



# 数据库权限修复
psql -U postgres -d postgres
\c zabbix
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA zabbix  TO zabbix;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public  TO zabbix;

# Zabbix 部署
sudo apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-agent -y
sudo sed -i 's/# HANodeName=/HANodeName=InnoVentBio-ZBX/g' /etc/zabbix/zabbix_server.conf
local_ip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
sudo sed -i "s/# NodeAddress=localhost/NodeAddress=$local_ip/g" /etc/zabbix/zabbix_server.conf

sudo sed -i "s/# DBHost=localhost/DBHost=10.10.60.125/g" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBPassword=/DBPassword=333999/g" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBPort=/DBPort=5433/g" /etc/zabbix/zabbix_server.conf

# 配置中文字体
sudo cp /usr/share/fonts/truetype/wqy/wqy-microhei.ttc /usr/share/zabbix/assets/fonts/graphfont.ttf