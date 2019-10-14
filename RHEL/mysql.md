# CentOS 7
These instructions are written [based on this guide](https://tecadmin.net/install-mysql-5-7-centos-rhel/)

```sh
yum install java-1.8.0-openjdk
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum update
yum install mysql-community-server

service mysqld start
grep 'A temporary password' /var/log/mysqld.log |tail -1

/usr/bin/mysql_secure_installation
```
