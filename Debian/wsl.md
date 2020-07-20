# SysV Init.D scripts for WSL

vim /etc/init.d/tomcat

```sh
#!/bin/bash

### BEGIN INIT INFO
# Provides: tomcat9
# Required-Start: $network
# Required-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start/Stop Tomcat server
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
start() {
 sh /opt/tomcat/latest/bin/startup.sh
}
stop() {
 sh /opt/tomcat/latest/bin/shutdown.sh
}

case $1 in
 start|stop) $1;;
 restart) stop; start;;
 *) echo "Run as $0 <start|stop|restart>"; exit 1;;
esac
```

## Run these commands after the script above has been saved

```sh
chmod 755 /etc/init.d/tomcat
update-rc.d tomcat defaults
```

To start Tomcat, instead of running `systemctl start tomcat`,  
you need to run `service tomcat start`
