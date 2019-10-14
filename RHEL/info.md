# CentOS 7
These instructions are written based on the following guides:  
[How to Install MySQL 5.7 on CentOS/RHEL 7/6, Fedora 27/26/25](https://tecadmin.net/install-mysql-5-7-centos-rhel/)  
[How to Install Latest MySQL 5.7.21 on RHEL/CentOS 7](https://dinfratechsource.com/2018/11/10/how-to-install-latest-mysql-5-7-21-on-rhel-centos-7/)  
[How To Install Nginx on CentOS 7](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-7)  

## Install required software
```sh
yum install epel-release
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum update
yum install java-1.8.0-openjdk
yum install mysql-community-server
```

## Get temporary MySQL Root password
```sh
service mysqld start
grep 'A temporary password' /var/log/mysqld.log |tail -1
```

## Configure/secure installation
```sh
/usr/bin/mysql_secure_installation
```

## Create database and user for XWiki

```sh
mysql -u root -p -e "create database xwiki default character set utf8 collate utf8_bin"
mysql -u root -p -e "grant all privileges on *.* to xwiki@localhost identified by 'SOMETHING74f3H3r3?'"
```

## Download and install Tomcat 9
TODO
```sh
groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
mkdir /opt/xwiki
curl http://apache.mirrors.spacedump.net/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz --output /opt/apache-tomcat-9.0.26.tar.gz
mkdir /opt/tomcat/9.0.26
tar xzvf /opt/apache-tomcat-9.0.26.tar.gz -C /opt/tomcat/9.0.26 --strip-components=1
ln -s /opt/tomcat/9.0.26 /opt/tomcat/latest
chown -RH tomcat: /opt/tomcat/latest/ /opt/xwiki
chmod +x /opt/tomcat/latest/bin/*.sh
```
## Download and install XWiki
TODO
