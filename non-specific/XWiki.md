# XWiki installation

## New installation

Download the .WAR into the folder `/opt/tomcat/latest/webapps`  

```sh
sudo wget -N http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/9.11.8/xwiki-platform-distribution-war-9.11.8.war --directory-prefix=/opt/install-files
```

Then we will rename it and put it in the webapps folder so it can be automatically expanded (unpacked)  

```sh
sudo unzip /opt/install-files/xwiki-platform-distribution-war-9.11.8.war -d /opt/tomcat/latest/webapps/xwiki/
```

At this point, it's time to start configuring XWiki itself as all requirements should be in place.

### /opt/tomcat/latest/webapps/xwiki/WEB-INF/hibernate.cfg.xml

**TODO:** Describe necessary configuration here to connect XWiki to a database

### /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.properties

**OBSERVE** Since we have defined `xwiki.data.dir` in `setenv.sh`, we can leave `environment.permanentDirectory` commented out in this file.  
I've left this note of the setting here to show a different way of handling it in case you don't want the setting to be globally known throughout the Tomcat-server.

### /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.cfg

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

### XWiki installation-process
  
1. Begin by opening [http://SERVER](http://SERVER) (if nginx isn't working, you should be able to reach it by using [http://SERVER:8080/xwiki/](http://SERVER:8080/xwiki/) instead)  
1. Create your XWiki user
1. Select XWiki Standard Flavor for installation and install it
  
#### XWiki database optimization
  
After-install tuneup of MySQL database

```sh
sudo mysql -u root -e "create index xwl_value on xwikilargestrings (xwl_value(50)); 
create index xwd_parent on xwikidoc (xwd_parent(50));
create index xwd_class_xml on xwikidoc (xwd_class_xml(20));
create index ase_page_date on  activitystream_events (ase_page, ase_date);
create index xda_docid1 on xwikiattrecyclebin (xda_docid);
create index ase_param1 on activitystream_events (ase_param1(200));
create index ase_param2 on activitystream_events (ase_param2(200));
create index ase_param3 on activitystream_events (ase_param3(200));
create index ase_param4 on activitystream_events (ase_param4(200));
create index ase_param5 on activitystream_events (ase_param5(200));" xwiki
```

## Upgrade

[XWiki.org - Upgrade instructions](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Upgrade)

```sh
wget -N http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/11.10.7/xwiki-platform-distribution-war-11.10.7.war  --directory-prefix=/opt/install-files
service stop tomcat
```

move the current `/opt/tomcat/latest/webapps/xwiki/` to a folder outside of tomcat to keep access to configuration-files  

```sh
mv /opt/tomcat/latest/webapps/xwiki /opt/install-files/old-xwiki
````

unpack latest WAR into `/opt/tomcat/latest/webapps/xwiki/` ( `unzip xwiki_VERSION.war -d /opt/tomcat/latest/webapps/xwiki/` )  
next step is to correct the permissions for the files by running these two commands:

```sh
find /opt/tomcat/latest/webapps/xwiki -type d -exec chmod 0750 {} \;
find /opt/tomcat/latest/webapps/xwiki -type f -exec chmod 0640 {} \;
```

Then we need to fix ownership

```sh
chown -RH tomcat: /opt/tomcat/latest/webapps/xwiki
```

Now it's time to go through the settings found in `/opt/tomcat/latest/webapps/xwiki/WEB-INF` and ensure it still uses the correct database and other settings.
You can use the colordiff tool in Linux to compare the old config-file with the new one like this:

```sh
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/hibernate.cfg.xml mv /opt/tomcat/latest/webapps/xwiki /opt/install-files/old-xwiki/WEB-INF/hibernate.cfg.xml | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/web.xml mv /opt/tomcat/latest/webapps/xwiki /opt/install-files/old-xwiki/WEB-INF/web.xml | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.cfg mv /opt/tomcat/latest/webapps/xwiki /opt/install-files/old-xwiki/WEB-INF/xwiki.cfg | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.properties mv /opt/tomcat/latest/webapps/xwiki /opt/install-files/old-xwiki/WEB-INF/xwiki.properties  | less -R
```

Start tomcat again.

```sh
service tomcat start
```
