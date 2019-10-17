[XWiki.org - Upgrade instructions](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Upgrade)

```sh
wget URLtoWAR
service stop tomcat
```
move the current `/opt/tomcat/latest/webapps/xwiki/` to a folder outside of tomcat to keep access to configuration-files  
```sh
mkdir /opt/tomcat/latest/old
mv /opt/tomcat/latest/webapps/xwiki/ /opt/tomcat/latest/old/xwiki/
````
unpack latest WAR into `/opt/tomcat/webapps/xwiki/` ( `unzip xwiki_VERSION.war -d /opt/tomcat/latest/webapps/xwiki/` )  
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
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/hibernate.cfg.xml /opt/tomcat/latest/old/xwiki/WEB-INF/hibernate.cfg.xml | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/web.xml /opt/tomcat/latest/old/xwiki/WEB-INF/web.xml | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.cfg /opt/tomcat/latest/old/xwiki/WEB-INF/xwiki.cfg | less -R
colordiff -yW"`tput cols`" /opt/tomcat/latest/webapps/xwiki/WEB-INF/xwiki.properties /opt/tomcat/latest/old/xwiki/WEB-INF/xwiki.properties  | less -R
```
Start tomcat again. service tomcat start
```
