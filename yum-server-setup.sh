##---------- Author : SKYRIM D/X ------------------------------------------------------------##
##---------- Github page : https://github.com/alexdu828/linux-shell-script-------------------##
##---------- Purpose : System security reinforcement script.---------------------------------##
##---------- Tested on : CentOS--------------------------------------------------------------## 
##---------- Updated version : v0.2 (Updated on  2023年03月07) -------------------------------##


# Installs the necessary packages, createrepo and httpd.
# Creates the YUM repository directory at /var/www/html/yumrepo.
# Copies the RPM packages to the YUM repository directory.
# Creates the YUM repository using createrepo.
# Configures Apache HTTP server to serve the YUM repository.
# Starts the Apache HTTP server.
# Enables the Apache HTTP server to start automatically on boot.
# You can save this script to a file, for example yum-server-setup.sh, and make it executable by running chmod +x yum-server-setup.sh. Then you can run the script with ./yum-server-setup.sh.

# Note: Please make sure to replace /path/to/rpm/packages in the script with the actual path to your RPM packages.

#!/bin/bash

# Install necessary packages
yum -y install createrepo httpd

# Create YUM repository directory
mkdir -p /var/www/html/yumrepo

# Copy RPM packages to the YUM repository directory
cp /path/to/rpm/packages/*.rpm /var/www/html/yumrepo

# Create the YUM repository
createrepo /var/www/html/yumrepo

# Configure the Apache HTTP server to serve the YUM repository
cat > /etc/httpd/conf.d/yumrepo.conf <<EOF
Alias /yumrepo /var/www/html/yumrepo
<Directory /var/www/html/yumrepo>
    Options Indexes FollowSymLinks MultiViews
    Require all granted
</Directory>
EOF

# Add Aliyun YUM repository
cat > /etc/yum.repos.d/aliyun.repo <<EOF
[aliyun]
name=Aliyun YUM repository
baseurl=http://mirrors.aliyun.com/centos/\$releasever/os/\$basearch/
gpgcheck=0
enabled=1
EOF
yum makecache

# Start the Apache HTTP server
systemctl start httpd.service

# Enable the Apache HTTP server to start automatically on boot
systemctl enable httpd.service