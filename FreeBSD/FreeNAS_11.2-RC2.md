# FreeNAS 11.2 RC2
## FreeNAS and Java
  
For Java to work in our Jail, we'll need to add a couple of Pre-Init scripts in FreeNAS since we can't run the two commands the installation of openjdk8 will ask us to do, nor will it work editing the jails fstab.

```
======================================================================

This OpenJDK implementation requires fdescfs(5) mounted on /dev/fd and
procfs(5) mounted on /proc.

If you have not done it yet, please do the following:

        mount -t fdescfs fdesc /dev/fd
        mount -t procfs proc /proc

To make it permanent, you need the following lines in /etc/fstab:

        fdesc   /dev/fd         fdescfs         rw      0       0
        proc    /proc           procfs          rw      0       0

======================================================================
```
  
### Tasks - Init/Shutdown scripts
#### fdescfs
  
|||
|:-|:-|
|**Type**|command|
|**Command**|`mount -t fdescfs null /mnt/iocage/jails/XWiki/root/dev/fd`|
|**When**|preinit|
|**Enabled**|yes
  
#### procfs
  
|||
|:-|:-|
|**Type**|command|
|**Command**|`mount -t procfs proc null /mnt/iocage/jails/XWiki/root/proc`|
|**When**|preinit|
|**Enabled**|yes
  
**Note** For these scripts to work, we will need to reboot the server before continuing!
  
## FreeBSD/FreeNAS install of packages
```sh
 pkg update
 pkg install openjdk8
 pkg install tomcat9
 pkg install nginx
```
  
## MySQL

```sh
pkg install mysql-connector-java-5.1.47 mysql57-server
```  

After installing our mysql57-server, we need to enable the service and start it.
```sh
printf '\n# Enable MySQL server\nmysql_enable="YES"\n' >> /etc/rc.conf
service mysql-server start
```

When it starts for the first time, it will create a file containing our MySQL-root users password, so we now need to take a look at `/root/.mysql_secret` and write down the password for later use.
```sh
cat /root/.mysql_secret
```

Just to make sure our password is correct, let's give it a try!
```sh
mysql --user=root --password="YOURPASSWORDHERE" --host=localhost
```

## PostgreSQL

**STUB-article** To be done at a later time!
  
## Tomcat

[Install Tomcat 8 In FreeBSD 10/10.1](https://www.unixmen.com/install-tomcat-7-freebsd-9-3/)  

Before we do anything, we will create our `setenv.sh` containing our settings to make Tomcat work better with XWiki.

```sh
vi /usr/local/apache-tomcat-9/bin/setenv.sh
```

In this file, add the following lines:

```
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
export CATALINA_OPTS="$CATALINA_OPTS -Dxwiki.data.dir=/usr/local/opt/xwiki/"
```

Then we'll change it's permissions:
```sh
chmod 755 /usr/local/apache-tomcat-9.0/bin/setenv.sh
```

And now we should take the time to create our permanent storage-folder for XWiki that we've defined in the startup-script for Tomcat.

```sh
mkdir -p /usr/local/opt/xwiki/
chown -R root:wheel /usr/local/opt/xwiki/
```

Before we start Tomcat for the first time, we'll configure `host-manager` and `manager` so we can login and manage our Tomcat-servlet using it's webGUI.
To do so, we need to edit these two files:
```sh 
/usr/local/apache-tomcat-9.0/webapps/manager/META-INF/context.xml
/usr/local/apache-tomcat-9.0/webapps/host-manager/META-INF/context.xml
```

Open these two files and edit the line `allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />` so your IP-address is allowed to connect.
If you want to allow all IPs starting with 192.168.100. for example, it could look like this:
```sh
allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|192\.168\.100\.\d+" />
```

After this, we want to edit `tomcat-users.xml` so we can login to the two different webGUIs, modify this line as you see fit, but add it before `</tomcat-users>`

```sh
<user username="tomcat-admin" password="MYSECRETPASSWORD" roles="admin-gui,manager-gui,manager-status"/>
```


Now we're ready to startup Tomcat!

```sh
/usr/local/apache-tomcat-9.0/bin/startup.sh
cd /usr/local/apache-tomcat-9.0/webapps/
curl http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/9.11.8/xwiki-platform-distribution-war-9.11.8.war --output xwiki.war
```

After this, we will need to wait for a moment until Tomcat has autoexpanded/deployed (unpacked) the war.  
The unpacked war will exist in `/usr/local/apache-tomcat-9.0/webapps/xwiki/` when it's done.  

When it's done unpacking, we can choose to stop Tomcat and then remove the war-file, or just keep the war-file, it shouldn't make a difference if it stays in the folder.