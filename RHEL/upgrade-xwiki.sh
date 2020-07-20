#!/usr/bin/env bash

# Functions
function getURL {
	if [ -z ${1} ]; then
			echo "No url was supplied as an argument for the script"
			echo "ex: $0 http://url.to.resource/file.name.here.tar.gz"
			exit
	elif grep -iqP "(^http[s]?):\/\/.*.war$" <<< ${1}; then
			XWikiURL=$1
	else
			echo "No valid url was supplied as an argument for the script"
			echo "ex: $0 http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/11.10.7/xwiki-platform-distribution-war-11.10.7.war"
			exit
	fi
}

function download_war {
	if ! wget -N ${XWikiURL} --directory-prefix=${InstallFiles}; then
			echo "Download failed, try again!"
			exit
	fi
}

function unzip_war {
	if ! unzip ${InstallFiles}/${NewWAR} -d ${WebApps}/xwiki/; then
			echo "Extraction of ${NewWAR} failed"
			exit
	fi
}

function unpackNewVersion {
	if ! [ -d ${WebApps}/xwiki ]; then
		mkdir ${WebApps}/xwiki
		unzip_war
	else
		rm -rf ${InstallFiles}/old_xwiki
		mv ${WebApps}/xwiki ${InstallFiles}/old_xwiki
		unzip_war
	fi
}

function setPermissions {
	find ${WebApps}/xwiki -type d -exec chmod 0750 {} \;
	find ${WebApps}/xwiki -type f -exec chmod 0640 {} \;
	chown -RH tomcat: ${WebApps}/xwiki
}
# End of functions

# Set initial values
getURL ${1}
NewWAR=`echo ${XWikiURL} | sed -r 's/.*\/(.*.war)/\1/'`
InstallFiles=/opt/install-files
WebApps=/opt/tomcat/latest/webapps
# End of initial values

service tomcat stop

download_war
unpackNewVersion
setPermissions



#################################################################

echo "Now it's time to go through the settings found in ${WebApps}/xwiki/xwiki/WEB-INF and ensure it still uses the correct database and other settings.
You can use the colordiff tool in Linux to compare the old config-file with the new one like this:
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/hibernate.cfg.xml ${InstallFiles}/old_xwiki/WEB-INF/hibernate.cfg.xml | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/web.xml ${InstallFiles}/old_xwiki/WEB-INF/web.xml | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/xwiki.cfg ${InstallFiles}/old_xwiki/WEB-INF/xwiki.cfg | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/xwiki.properties ${InstallFiles}/old_xwiki/WEB-INF/xwiki.properties  | less -R
# Start tomcat again.
service tomcat start"
