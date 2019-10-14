# CentOS 7
These instructions are written based on the following guides:  
[How to Install MySQL 5.7 on CentOS/RHEL 7/6, Fedora 27/26/25](https://tecadmin.net/install-mysql-5-7-centos-rhel/)  
[How to Install Latest MySQL 5.7.21 on RHEL/CentOS 7](https://dinfratechsource.com/2018/11/10/how-to-install-latest-mysql-5-7-21-on-rhel-centos-7/)  
[How To Install Nginx on CentOS 7](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-7)  

# Install required software
```sh
yum install epel-release
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
yum update
yum install java-1.8.0-openjdk-devel
yum install mysql-community-server
yum install wget
```

# MySQL

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
## Fine-tune for XWiki

We will need to allow larger packets for situations where we upload large documents.
First, run: `vi /etc/my.cnf`
and add the following line:

```
max_allowed_packet = 512M
```

# Tomcat 9
**TODO**

```sh
groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
mkdir /opt/xwiki
wget http://apache.mirrors.spacedump.net/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz 
mkdir /opt/tomcat/9.0.26
tar xzvf apache-tomcat-9.0.26.tar.gz -C /opt/tomcat/9.0.26 --strip-components=1
ln -s /opt/tomcat/9.0.26 /opt/tomcat/latest
chown -RH tomcat: /opt/tomcat/latest/ /opt/xwiki
chmod +x /opt/tomcat/latest/bin/*.sh
```

## Configure

### Tomcat environment
Now we need to edit the file where we'll set our environment-settings:  
`vi /opt/tomcat/latest/conf/setenv.sh`

```sh
#! /bin/bash 
# Better garbage-collection 
export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseParallelGC" 
# Instead of 1/6th or up to 192MB of physical memory for Minimum HeapSize 
export CATALINA_OPTS="$CATALINA_OPTS -Xms512M" 
# Instead of 1/4th of physical memory for Maximum HeapSize 
export CATALINA_OPTS="$CATALINA_OPTS -Xmx1536M" 
# Start the jvm with a hint that it's a server 
export CATALINA_OPTS="$CATALINA_OPTS -server" 
# Headless mode 
export JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true" 
# Allow \ and / in page-name 
export CATALINA_OPTS="$CATALINA_OPTS -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true" 
export CATALINA_OPTS="$CATALINA_OPTS -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true" 
# Set permanent directory 
export CATALINA_OPTS="$CATALINA_OPTS -Dxwiki.data.dir=/opt/xwiki/"
```

### Set up as a systemd service

The command `alternatives --config java` will give us the path to our Java-installation.
Remove the ending `/jre/bin/java/` and use that as the variable `JAVA_HOME`

In CentOS 7, this is the path I got for java-1.8.0-openjdk-devel: `/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64`

`vi /etc/systemd/system/tomcat.service`

```sh
[Unit]
Description="Apache Tomcat Web Application Container"
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:///dev/urandom"
ExecStart="/opt/tomcat/latest/bin/startup.sh"
ExecStop="/opt/tomcat/latest/bin/shutdown.sh"

UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```

After saving `/etc/systemd/system/tomcat.service`, run the following commands to start the service and to allow access to the service.  

```sh
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat
systemctl status tomcat
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
```

### manager & host-manager

Edit `/opt/tomcat/webapps/manager/META-INF/context.xml`
and `/opt/tomcat/webapps/host-manager/META-INF/context.xml`
to allow your computer (as the admin) to access Tomcat's manager and host-manager-application:

`allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|192\.168\.100\.\d+" />`

The example above will give access to the host-manager and manager-applications of Tomcat from any IP that starts with `192.168.100.X`, so modify it to suit your needs.

### Add support for MySQL

```sh
cd /opt/tomcat/latest/lib/
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.48.tar.gz
tar xzf mysql-connector-java-5.1.48.tar.gz 
mv mysql-connector-java-5.1.48/*.jar ./
rm -rf mysql-connector-java-5.1.48/
```

# XWiki
TODO

# NginX
