#!/bin/bash
#
# Program: Install Mobicents
# Author: Gonzalo Gasca Meza <gonzalo@cloudtree.io>
# This program is distributed under the terms of the GNU Public License V2
trap "rm .f 2> /dev/null; exit" 0 1 3
# Initialize our own variables:
MOBICENTS_URL="https://github.com/Mobicents/sip-servlets/releases/download/v3.0.564/mss-3.0.564-jboss-as-7.2.0.Final.zip"
MOBICENTS_DIR="mss-3.0.564-jboss-as-7.2.0.Final"
#Update system
apt-get install zip -y

# Get Mobicents
cd /usr/local/src
wget $MOBICENTS_URL
unzip $MOBICENTS_URL
cd $MOBICENTS_DIR

