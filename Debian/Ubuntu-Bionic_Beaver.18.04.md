# Ubuntu 18.04

## Unsolved issues

The current nginX-configuration doesn't handle all characters perfectly ( **/** for example), this could be a limit in how nginX handles redirects/acting as reverse proxy, but I will have to look into that later.
At the very least, I need to verify what characters are causing issues, I've for example seen similiar issues when using **IIS/URL Rewrite** as a reverse proxy

## Install Java Runtime Environment 

As of 2018-11-22, XWiki doesn't support Java 9+ so we need to install a Java 8 Runtime. 
For licensing-reasons, the instructions below describe how to install the OpenJDK.

```sh
 sudo add-apt-repository universe 
 sudo apt-get update 
 sudo apt-get install openjdk-8-jre-headless
```


## Install XWiki from repositories 

[Installation using Debian (.DEB) packages](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Installation/InstallationViaAPT/)  
The description in the link above doesn't work in 18.04.1 LTS, the packages aren't compatible yet (2018-11-22) for Bionic Beaver. 
As such, installation must be done manually. 
**Even if the repository would work, the part about nginx still has to be done manually**

## Manual installation 

### MySQL server

 
```sh
 sudo apt-get install mysql-server-5.7 
 sudo mysql -u root -e "create database xwiki default character set utf8 collate utf8_bin" 
 sudo mysql -u root -e "grant all privileges on *.* to xwiki@localhost identified by 'xwiki'" 
 sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Edit `mysqld.cnf` so the line with max_allowed_packet looks like this: 

`max_allowed_packet      = 512M `

### nginx 

```sh
 sudo apt-get install nginx 
 sudo ufw allow http 
 sudo ufw allow https
```

Now we need to configure nginx to work as a reverse-proxy so any users trying to access the server on port 80 (default HTTP) will behind the curtains reach our Tomcat/XWiki on port 8080 

```nginx
## Expires map based upon HTTP Response Header Content-Type
#    map $sent_http_content_type $expires
#{
#       default                 off;
#       text/html               epoch;
#       text/css                1h;
#       text/javascript         1h;
#       application/javascript  1h;
#       ~image/                 1m;
#}

## Expires map based upon request_uri (everything after hostname)
map $request_uri $expires {
    default off;
    ~*\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)(\?|$) 1h;
    ~*\.(css) 0m;
}
expires $expires;

server {
    listen       80;
    server_name  wiki.DOMAIN.TLD wiki; 
    charset utf-8;
    client_max_body_size 64M;

    # Normally root should not be accessed, however, root should not serve files that might compromise the security of your server.
    root /var/www/html;

    location /
    {
        # All "root" requests will have /xwiki appended AND redirected to wiki.kibino.local
        rewrite ^ $scheme://$server_name/xwiki$request_uri? permanent;
    }

    location ^~ /xwiki
    {
       # If path starts with /xwiki - then redirect to backend: XWiki application in Tomcat
       # Read more about proxy_pass: http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass
       proxy_pass              http://localhost:8080;
       proxy_cache             off;
       proxy_set_header        X-Real-IP $remote_addr;
       proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header        Host $http_host;
       proxy_set_header        X-Forwarded-Proto $scheme;
       expires                 $expires;
    }
}
```

# Tomcat 9

## Create user for Tomcat

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

You'll need to edit `/opt/tomcat/latest/conf/server.xml` and ensure that the connector for port 8080 has this option: `URIEncoding="UTF-8"`  

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
 
The command `update-java-alternatives -l` will give us the path to our JAVA-installation, use this and ensure that `JAVA_HOME` points to that path. 

```sh
 update-java-alternatives -l 
 sudo nano /etc/systemd/system/tomcat.service
```

Remember to verify JAVA_HOME path before saving the contents below! 

`vi /etc/systemd/system/tomcat.service`

```ini
[Unit] 
Description=Apache Tomcat Web Application Container 
After=network.target 

[Service] 
Type=forking 

Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64 
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid 
Environment=CATALINA_HOME=/opt/tomcat 
Environment=CATALINA_BASE=/opt/tomcat 
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC' 
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom' 
ExecStart=/opt/tomcat/bin/startup.sh 
ExecStop=/opt/tomcat/bin/shutdown.sh 

User=tomcat 
Group=tomcat 
UMask=0007 
RestartSec=10 
Restart=always 

[Install] 
WantedBy=multi-user.target
```


After saving the file above, run the following commands to start the service and to allow access to the service. 

```sh
 sudo systemctl daemon-reload 
 sudo systemctl start tomcat 
 sudo systemctl enable tomcat 
 sudo systemctl status tomcat 
 sudo ufw allow 8080/tcp
```
 
### manager & host-manager

Edit `/opt/tomcat/webapps/manager/META-INF/context.xml`
and `/opt/tomcat/webapps/host-manager/META-INF/context.xml`
to allow your computer (as the admin) to access Tomcat's manager and host-manager-application:

`allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|192\.168\.100\.\d+" />`

The example above will give access to the host-manager and manager-applications of Tomcat from any IP that starts with `192.168.100.X`, so modify it to suit your needs.

**TODO:** Describe how to create users for **manager** & **host-manager**


## Install MySQL Connector 

We need to aquire a MySQL Connector so Java/Tomcat/XWiki can access the MySQL-database.  
As of 2018-11-22, __MySQL 8.0 is NOT compatible with any version of XWiki__ so we will be using 5.1.47.  
Since we will need to traverse the folders that we don't have permissions to, we will need to switch to a superuser.  
Either use `su` or `sudo -i` to temporarily switch to a user with superuser-permissions.  
When done, type `exit` to return to your regular "non-privileged" user.
  
```sh
 sudo -i
 cd /opt/tomcat/lib/
 wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz
 tar xzf mysql-connector-java-5.1.47.tar.gz 
 mv mysql-connector-java-5.1.47/*.jar /opt/tomcat/lib/
 exit
```

## Fix Java-settings

By default, installing **openjdk-8-jre-headless** will add a setting that can cause issues with extensions using org.jfree.chart.JFreeChart  
To rectify this, edit **/etc/java-8-openjdk/accessibility.properties** and comment out the line about assistive_technologies by putting the hash-sign at the beginning of the line like below  

```ini
#assistive_technologies=org.GNOME.Accessibility.AtkWrapper
```

# XWiki 

Download the .WAR into the folder `/opt/tomcat/webapps`  
```sh
sudo wget http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/9.11.8/xwiki-platform-distribution-war-9.11.8.war --directory-prefix=/opt/tomcat/ 
```

Then we will rename it and put it in the webapps folder so it can be automatically expanded (unpacked)  
```sh
sudo mv xwiki-platform-distribution-war-9.11.8.war /opt/tomcat/webapps/xwiki.war 
```

After this, we'll need to restart the Tomcat-service so it will actually expand our .war-file  
```sh
sudo systemctl restart tomcat 
```

This will incur a heavy load on the server for a short while (should be less then 2 minutes) as it unpacks the package into a folder of similiar name as the file.  
If you've followed my instructions so far, it should end up being:
```sh
/opt/tomcat/webapps/xwiki/
```
 
When this is done and you can visit any of the Tomcat pages ( http://SERVER:8080/manager/ http://SERVER:8080/host-manager/ ) it should have finished deploying/unpacking our .war-file, and thus it's time to remove the .war-file
First we'll need to stop Tomcat so it doesn't remove the deployed application when the .war-file is removed, then we can run this:
```sh
sudo rm -rf /opt/tomcat/webapps/xwiki.war
```

At this point, it's time to start configuring XWiki itself as all requirements should be in place.
 
## /opt/tomcat/webapps/xwiki/WEB-INF/hibernate.cfg.xml

**FIX ME!**
 
 
## /opt/tomcat/webapps/xwiki/WEB-INF/xwiki.properties 

These are the settings necessary to edit before we can continue with the actual installation of XWiki. 
Since we have defined `xwiki.data.dir` in `setenv.sh`, this setting can be left commented out,  
I've left this note of the setting here to show a different way of handling it in case you don't want the setting to be globally known throughout the Tomcat-server.

```ini
environment.permanentDirectory=/opt/xwiki/ 
```

## /opt/tomcat/webapps/xwiki/WEB-INF/xwiki.cfg 

We need to edit these two lines so we aren't using the default keys (out of security-reasons).  
```ini
xwiki.authentication.validationKey=totototototototototototototototo 
xwiki.authentication.encryptionKey=titititititititititititititititi
```
  
We also want to modify how attachments are stored, in later versions of XWiki (10.2 and later), the default is to store attachments as files directly on the drive. 
```ini
#-# [Since 9.0RC1] The default document content recycle bin storage. Default is hibernate. 
#-# This property is only taken into account when deleting a document and has no effect on already deleted documents. 
xwiki.store.recyclebin.content.hint=file 

#-# The attachment storage. [Since 3.4M1] default is hibernate. 
xwiki.store.attachment.hint=file 

#-# The attachment versioning storage. Use 'void' to disable attachment versioning. [Since 3.4M1] default is hibernate. 
xwiki.store.attachment.versioning.hint=file 

#-# [Since 9.9RC1] The default attachment content recycle bin storage. Default is hibernate. 
#-# This property is only taken into account when deleting an attachment and has no effect on already deleted documents. 
xwiki.store.attachment.recyclebin.content.hint=file
```
We also want to set the "correct" url so the cookies will be correct, since XWiki won't know it's behind a reverseproxy by default. This is done by adding this line to xwiki.cfg
```ini
xwiki.home=http://wiki.DOMAIN.TLD/
```

  
## XWiki installation-process 
  
1. Begin by opening [http://SERVER](http://SERVER) (if nginx isn't working, you should be able to reach it by using [http://SERVER:8080/xwiki/](http://SERVER:8080/xwiki/) instead)  
1. Create your XWiki user
1. Select XWiki Standard Flavor for installation and install it 
  
  
## XWiki database optimization 
  
After-install tuneup of MySQL database 
```sh
sudo mysql -u root -e "create index xwl_value on xwikilargestrings (xwl_value(50)); create index xwd_parent on xwikidoc (xwd_parent(50)); create index xwd_class_xml on xwikidoc (xwd_class_xml(20)); create index ase_page_date on  activitystream_events (ase_page, ase_date); create index xda_docid1 on xwikiattrecyclebin (xda_docid); create index ase_param1 on activitystream_events (ase_param1(200)); create index ase_param2 on activitystream_events (ase_param2(200)); create index ase_param3 on activitystream_events (ase_param3(200)); create index ase_param4 on activitystream_events (ase_param4(200)); create index ase_param5 on activitystream_events (ase_param5(200));" xwiki
```
 
# Backup-management 
  
[Backup/Restore](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Backup)  
Configure the script below to run on a daily basis through a cron-job 
  
```sh
#!/bin/bash

###############################
# global variables for script #
###############################

Date="$(date +"%Y.%m.%d-%H.%M.%S")"
BackupFolder="/opt/backup"
MySQLBackup="$BackupFolder/mysql/xwiki_db_backup-$Date.sql"
FilesBackup="$BackupFolder/files/xwiki_files_backup-$Date.tar.gz"
Logs="$BackupFolder/logs"
Host="localhost"
User="xwiki"
Pass="xwiki"
Db="xwiki"
Options="--add-drop-database --max_allowed_packet=1G --comments --dump-date --log-error=$Logs/$Date/mysqldump.log"

###################################
# Make a SQL-dump and compress it #
###################################

if mysqldump --host=$Host --password=$Pass --user=$User --databases $Db $Options > $MySQLBackup; then
        if tar -zcf $MySQLBackup.tar.gz $MySQLBackup ; then
               rm -rf $MySQLBackup
        else
               echo "The compression of the sql-dump was unsuccessful" >> $Logs/$Date/mysqldump.log
        fi
else
        echo "The mysqldump was unsuccessful!" >> $Logs/$Date/mysqldump.log
fi


################
# Backup files #
################

if ! tar -czf $FilesBackup /opt/xwiki /opt/tomcat/latest/webapps/ /opt/tomcat/latest/work/; then
        echo "The backup was unsuccessful!" >> $Logs/$Date/files.log;
fi


#####################
# Clean old backups #
#####################

find $BackupFolder -daystart -mtime +28 -type f -name "*.tar.gz" -print0 | xargs -0 -r rm
find $BackupFolder -daystart -mtime +7 -type f -name "*.sql" -print0 | xargs -0 -r rm
find $BackupFolder -daystart -mtime +90 -type f -name "*.log" -print0 | xargs -0 -r rm
```


Add the following line to `/etc/crontab` so our scripts runs daily at 01:00 (AM)

```cron
0 1 * * *   root    /opt/backup/backup.sh > /dev/null 2>&1
```
  
# Firewall 
  
Now that things work, it's time to start securing it. By now, all that's left to allow should be SSH for remote control:  
```sh
 sudo ufw allow ssh 
 sudo ufw status
```
  
This should return with `Status: inactive`, so we now need to activate the firewall by running: 
```sh
sudo ufw enable
```
  
If you run the status-command again, it should look like this: 
```sh
root@xwiki-server:/# ufw status 
Status: active 
 

To               Action      From 

--               ------      ---- 

8080/tcp         ALLOW       Anywhere 
22/tcp           ALLOW       Anywhere 
80/tcp           ALLOW       Anywhere 
443/tcp          ALLOW       Anywhere 
8080 (v6)        ALLOW       Anywhere (v6) 
22/tcp (v6)      ALLOW       Anywhere (v6) 
80/tcp (v6)      ALLOW       Anywhere (v6) 
443/tcp (v6)     ALLOW       Anywhere (v6)
```
  
There really isn't any good reason to leave port 8080/tcp entirely open, even if you don't expose the port to the internet.
A better solution would be to only allow access from the IP/subnet where the admins reside and localhost (so nginx can access it), but I'll leave that up to you to decide for yourself.

Here are two links that can tell you more about ufw
[How To Set Up a Firewall with UFW on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04)
[UFW - Ubuntu Community](https://help.ubuntu.com/community/UFW)
