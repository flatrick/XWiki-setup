#!/usr/bin/env bash

# Get download URL for XWiki war package
if [ -z ${1} ]; then
        echo "No url was supplied as an argument for the script"
        echo "ex: $0 http://url.to.resource/file.name.here.tar.gz"
        exit #exit script
elif grep -iqP "(^http[s]?):\/\/.*.war$" <<< ${1}; then
        XWikiURL=$1
else
        echo "No valid url was supplied as an argument for the script"
        echo "ex: $0 http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/11.10.7/xwiki-platform-distribution-war-11.10.7.war"
        exit #exit script
fi

# Set initial values
NewWAR=`echo ${XWikiURL} | sed -r 's/.*\/(.*.war)/\1/'`
InstallFiles=/opt/install-files
WebApps=/opt/tomcat/latest/webapps

## Stop tomcat
service tomcat stop

## Download, move current version and unpack
cd ${InstallFiles}
if wget -N ${XWikiURL}; then
        if ! [ -d ${WebApps}/xwiki ]; then
                mkdir ${WebApps}/xwiki
                unzip ${InstallFiles}/${NewWAR} -d ${WebApps}/xwiki/
        else
                rm -rf ${InstallFiles}/old_xwiki
                mv ${WebApps}/xwiki ${InstallFiles}/old_xwiki
                unzip ${InstallFiles}/${NewWAR}  -d ${WebApps}/xwiki/
        fi
else
        echo "Download failed, try again!"
        exit
fi

## Set the correct permissions and ownership
find ${WebApps}/xwiki -type d -exec chmod 0750 {} \;
find ${WebApps}/xwiki -type f -exec chmod 0640 {} \;
chown -RH tomcat: ${WebApps}/xwiki


#################################################################

echo "Now it's time to go through the settings found in ${WebApps}/xwiki/xwiki/WEB-INF and ensure it still uses the correct database and other settings.
You can use the colordiff tool in Linux to compare the old config-file with the new one like this:

# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/hibernate.cfg.xml ${InstallFiles}/old_xwiki/WEB-INF/hibernate.cfg.xml | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/web.xml ${InstallFiles}/old_xwiki/WEB-INF/web.xml | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/xwiki.cfg ${InstallFiles}/old_xwiki/WEB-INF/xwiki.cfg | less -R
# colordiff -yW"\`tput cols\`" ${WebApps}/xwiki/WEB-INF/xwiki.properties ${InstallFiles}/old_xwiki/WEB-INF/xwiki.properties  | less -R

# Start tomcat again.
service tomcat start"
