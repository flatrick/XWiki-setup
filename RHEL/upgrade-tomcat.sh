#!/usr/bin/env bash

# Functions
function getURL {
	if [ -z ${1} ]; then
			echo "No url was supplied as an argument for the script"
			echo "ex: $0 http://url.to.resource/file.name.here.tar.gz"
			exit
	elif grep -iqP "(^http[s]?):\/\/.*.tar.gz$" <<< ${1}; then
			TomcatURL=${1}
	else
			echo "No valid url was supplied as an argument for the script"
			echo "ex: $0 http://apache.mirrors.spacedump.net/tomcat/tomcat-9/v9.0.37/bin/apache-tomcat-9.0.37.tar.gz"
	exit
fi
}

function download_tomcat {
	if ! wget -N ${TomcatURL} --directory-prefix=${InstallFiles}; then
		echo "Download failed, try again!"
		exit
	fi
}

function unpack_tar {
	if ! [ -d ${TomcatDest}/${NewTomcat} ]; then mkdir ${TomcatDest}/${NewTomcat};  fi
	if ! tar xzvf ${InstallFiles}/apache-tomcat-${NewTomcat}.tar.gz -C ${TomcatDest}/${NewTomcat} --strip-components=1; then
			echo "Extraction of apache-tomcat-${NewTomcat}.tar.gz failed"
			exit
	fi
}

function copyToNewTomcat {
	cp -a ${OldVersion}/webapps/xwiki ${TomcatDest}/latest/webapps/
	cp -a ${OldVersion}/webapps/manager/META-INF/context.xml ${TomcatDest}/latest/webapps/manager/META-INF/
	cp -a ${OldVersion}/webapps/host-manager/META-INF/context.xml ${TomcatDest}/latest/webapps/host-manager/META-INF/
	cp -a ${OldVersion}/bin/setenv.sh ${TomcatDest}/latest/bin/
	cp -a ${OldVersion}/lib/mysql-connector*.jar ${TomcatDest}/latest/lib/
}

function SetSymlinks {
	if [ -L ${TomcatDest}/latest ]; then OldVersion=`readlink ${TomcatDest}/latest`; rm ${TomcatDest}/latest; fi
	ln -s ${TomcatDest}/${NewTomcat} ${TomcatDest}/latest
}

function SetPermissions {
	chown -RH tomcat: ${TomcatDest}/latest
	chmod +x ${TomcatDest}/latest/bin/*.sh
}
# End of functions

# Set initial values
getURL ${1}
NewTomcat=`echo $TomcatURL | sed -r 's/.*?(apache-tomcat-)([0-9|\.]*)(.tar.gz)/\2/'`
InstallFiles=/opt/install-files
TomcatDest=/opt/tomcat
# End of initial values

cd ${InstallFiles}
download_tomcat
unpack_tar

service tomcat stop

copyToNewTomcat
SetSymlinks
SetPermissions


#################################################################

echo "We need to ensure that all custom settings are configured in the new tomcat-installation:

# colordiff -yW"\`tput cols\`" ${TomcatDest}/latest/conf/server.xml ${OldVersion}/conf/server.xml  | less -R

Most likely, we will be missing URIEncoding="UTF-8" on the connector for port 8080, but things could change with later versions of TomCat.

After ensuring all the necessary settings have been copied, it's time to start up our new version of Tomcat!
# service tomcat start"
