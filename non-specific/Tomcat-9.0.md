# Tomcat 9
This page is meant to describe how to install, configure and update Tomcat in a generic way that hopefully will work on any UNIX-based OS.

## Create user for Tomcat

(Taken from instructions for CentOS7)
```sh
groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
```

## Create the necessary folders

```sh
mkdir /opt/xwiki
mkdir /opt/tomcat/9.0.26
```

## Download & Unpack/Symlink Tomcat 

```sh
wget http://apache.mirrors.spacedump.net/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz 
tar xzvf apache-tomcat-9.0.26.tar.gz -C /opt/tomcat/9.0.26 --strip-components=1
ln -s /opt/tomcat/9.0.26 /opt/tomcat/latest
```

## Configure

### Tomcat environment

Now we need to edit the file where we'll set our environment-settings:  
`vi /opt/tomcat/latest/bin/setenv.sh`

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

### Configure Tomcat to use UTF-8 encoding

You'll need to edit `conf/server` and ensure that the connector for port 8080 has this option: `URIEncoding="UTF-8"`  

Example on how it could look:  
```xml
<Connector port="8080" maxHttpHeaderSize="8192"
    maxThreads="150" minSpareThreads="25" maxSpareThreads="75"
    enableLookups="false" redirectPort="8443" acceptCount="100"
    connectionTimeout="20000" disableUploadTimeout="true"
    URIEncoding="UTF-8"/>
```

### Set correct permissions

```sh
chown -RH tomcat: /opt/tomcat/latest/ /opt/xwiki
chmod +x /opt/tomcat/latest/bin/*.sh
```

## Set up as a systemd service

(Different versions of Linux will give you different ways of figuring out this path, the instructions below are for CentOS7)  

The command `alternatives --config java` will give us the path to our Java-installation.  
Remove the ending `/jre/bin/java/` and use that as the variable `JAVA_HOME`  

This is the path I got for java-1.8.0-openjdk-devel: `/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64`

Now it's time to create and edit our service-file for Tomcat:  
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
