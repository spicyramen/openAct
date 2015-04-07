#!/bin/bash

#
# Program: Install Mobicents
# Author: Gonzalo Gasca Meza <gonzalo@cloudtree.io>
# This program is distributed under the terms of the GNU Public License V2
trap "rm .f 2> /dev/null; exit" 0 1 3


# Initialize our own variables:
MOBICENTS_URL="https://github.com/Mobicents/sip-servlets/releases/download/v3.0.564/mss-3.0.564-jboss-as-7.2.0.Final.zip"
MOBICENTS_FILE="mss-3.0.564-jboss-as-7.2.0.Final.zip"
MOBICENTS_DIR="mss-3.0.564-jboss-as-7.2.0.Final"
IP_ADDR=`ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/{split($2,_," ");print _[1]}'`

MCUWEB_URL="https://github.com/spicyramen/openAct/blob/master/mcuWeb/mcuWeb.war"
set -e
#Update system
apt-get install zip -y

function check {
	ERROR_CODE=$(echo "$?")
    	 if [ $ERROR_CODE -ne 0 ]; then
	       	echo "Error ($ERROR_CODE) Fatal Exception occurred"
	        exit 1
    	 fi
     	return 0
}

# Get Mobicents
cd /usr/local/src
wget $MOBICENTS_URL
check;
unzip $MOBICENTS_FILE
rm -rf $MOBICENTS_FILE
sed -r 's/(enable-welcome-root=")[^"]+"/\1false"/' $MOBICENTS_DIR/standalone/configuration/standalone-sip.xml
cp $MOBICENTS_DIR/standalone/configuration/standalone-sip.xml $MOBICENTS_DIR/bin
cd $MOBICENTS_DIR/bin
# get McuWeb SAR
echo "Getting mcuWeb"
cd /usr/local/src
wget $MCUWEB_URL
sleep 2
mv mcuWeb.war $MOBICENTS_DIR/standalone/deployments/

echo "Kill any existing instance"
./jboss-cli.sh --connect command=:shutdown

echo "Start Mobicents"
./standalone.sh -b $IP_ADDR -c standalone-sip.xml &
