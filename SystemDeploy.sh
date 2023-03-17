#!/bin/bash
##---------- Author : SKYRIM D/X ------------------------------------------------------------##
##---------- Github page : https://github.com/alexdu828/linux-shell-script-------------------##
##---------- Tested on : ubuntu 20.04 LTS----------------------------------------------------##
##---------- Updated version : v0.1 (Updated on  2023年03月16 -------------------------------##
##-----NOTE: This script requires root privileges, otherwise one could run the script -------##
##---- as a sudo user who got root privileges. ----------------------------------------------##
##----------- "sudo /bin/bash <ScriptName>" -------------------------------------------------##

#variables

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

## 配置Patroni
## Patroni是一个管理Postgres配置的开源Python软件包. 它可以配置为处理复制,备份和恢复等任务.
sudo apt install python python3-pip
mkdir ~/.pip
cat << EOF > ~/.pip/pip.conf
[global] 
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = https://pypi.tuna.tsinghua.edu.cn  # trusted-host 此参数是为了避免麻烦,否则使用的时候可能会提示不受信任
EOF
sudo pip install --upgrade setuptools

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



###########################################Memo################################################
## 数据库群集与负载均衡环境配置,需要联网
## 3台PGSQLDB节点,采用ClusterControl(Repmgr+实现高可用,2台HAProxy+keepalive节点
###############################################################################################

echo -e " \033[032m 
###############################################################################################

|  __ \|  ____|  __ \| |    / __ \ \   / / |  __ \|  _ \|  ____| \ | \ \    / /
| |  | | |__  | |__) | |   | |  | \ \_/ /  | |  | | |_) | |__  |  \| |\ \  / / 
| |  | |  __| |  ___/| |   | |  | |\   /   | |  | |  _ <|  __| | .   | \ \/ /  
| |__| | |____| |    | |___| |__| | | |    | |__| | |_) | |____| |\  |  \  /   
|_____/|______|_|    |______\____/  |_|    |_____/|____/|______|_| \_|   \/                                          
    
###############################################################################################\033[00m "
echo -e "\033[031m____________________________________________ \033[00m"							     
echo -e "\033[031m|##########################################| \033[00m"							     
echo -e "\033[031m|##as a sudo user who got root privileges##| \033[00m"							     
echo -e "\033[031m|##########################################| \033[00m"							     
echo -e "\033[031m____________________________________________ \033[00m"


## 3台PGSQLDB节点安装


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