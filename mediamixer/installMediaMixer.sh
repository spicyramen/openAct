#!/bin/bash
#
# Program: Install MCU mixer in Ubuntu 12.04+
# Author: Gonzalo Gasca Meza <gonzalo@cloudtree.io>
# This program is distributed under the terms of the GNU Public License V2

trap "rm .f 2> /dev/null; exit" 0 1 3
# Initialize our own variables:
CERT_DURATION=1825
CERT_COUNTRY="US"
CERT_STATE="California"
CERT_LOCATION="Milpitas"
CERT_ORGANIZATION="Engineering"

# This line is in Make file, we will replace it
ORIG_CERT="@openssl req -nodes -new -x509 -keyout \$(BIN)/mcu.key -out \$(BIN)/mcu.crt"
NEW_CERT="@openssl req -nodes -days $CERT_DURATION -new -x509 -keyout \$(BIN)/mcu.key -out \$(BIN)/mcu.crt -subj \"/C=$CERT_COUNTRY/ST=$CERT_STATE/L=$CERT_LOCATION/O=$CERT_ORGANIZATION/CN=$HOSTNAME\""

# Check
function check {
	ERROR_CODE=$(echo "$?")
    	 if [ $ERROR_CODE -ne 0 ]; then
	       	echo "Error ($ERROR_CODE) Fatal Exception occurred"
	        exit 1
    	 fi
     	return 0
}

#Update system
apt-get update
apt-get update --fix-missing

#Install development Libraries
#MCU media mixer

apt-get install wget libgsm1-dev g++ make libtool subversion git automake subversion autoconf libgcrypt11-dev libjpeg8-dev libssl-dev -y
 
echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
ldconfig
 
#
# Needed by webrtc 
#

apt-get install unzip bzip2 pkg-config libgtk2.0-dev libnss3-dev libxtst-dev libxss-dev libdbus-1-dev libdrm-dev libgconf2-dev libgnome-keyring-dev libpci-dev libudev-dev libogg-dev -y
 
#
# External source code checkout
#
mkdir -p /usr/local/src
cd /usr/local/src
 
wget http://downloads.sourceforge.net/project/xmlrpc-c/Xmlrpc-c%20Super%20Stable/1.16.35/xmlrpc-c-1.16.35.tgz
tar xvzf xmlrpc-c-1.16.35.tgz
wget http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
tar xvzf speex-1.2rc1.tar.gz
wget http://downloads.xiph.org/releases/opus/opus-1.0.2.tar.gz
tar xvzf opus-1.0.2.tar.gz
wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
tar xvzf yasm-1.2.0.tar.gz

# Get latest version of code add checks 
svn checkout svn://svn.code.sf.net/p/mcumediaserver/code/trunk medooze
check;
svn checkout http://mp4v2.googlecode.com/svn/trunk/ mp4v2
check;
git clone git://git.videolan.org/ffmpeg.git
check;
git clone git://git.videolan.org/x264.git
check;
git clone http://git.chromium.org/webm/libvpx.git
check;
git clone https://github.com/cisco/libsrtp
check;

#
# Compiling yasm 1.2
#
cd yasm-1.2.0
./configure
make
make install
cd ..
 
#
# Compiling X264
#
 
cd /usr/local/src/x264
./configure --enable-debug --enable-shared --enable-pic
make
make install
cd ..

#
# Compiling FFMPEG
#
 
cd /usr/local/src/ffmpeg
./configure --enable-shared --enable-gpl --enable-nonfree --disable-stripping --enable-zlib --enable-avresample --enable-decoder=png
make
make install
cd ..


apt-get install openjdk-7-jdk -y
update-alternatives --config javac
update-alternatives --config java
update-alternatives --config javaws
update-alternatives --config javap
update-alternatives --config jar
update-alternatives --config jarsigner
echo $JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64


#
# Compiling XMLRPC-C
#
 
cd /usr/local/src/xmlrpc-c-1.16.35
./configure
make
make install
cd ..


#
# Compiling mp4v2
#
 
cd /usr/local/src/mp4v2
autoreconf -fiv
./configure
make
make install

#
# Compiling Speex
#
 
cd /usr/local/src/libvpx
./configure --enable-shared
make
make install

#
# Compiling Speex
#
 
cd /usr/local/src/speex-1.2rc1
./configure
make
make install

#
# Compiling Opus
#
 
cd /usr/local/src/opus-1.0.2
./configure
make
make install

#
# Compiling libsrtp
#
 
cd /usr/local/src/libsrtp
./configure
make
make install
cd ..
#
# Install depot_tools, you shall use an account different than root
#
svn co http://src.chromium.org/chrome/trunk/tools/depot_tools
export PATH="$PATH":/usr/local/src/depot_tools

#
# Compile WebRTC VAD and signal processing libraries
#
cd /usr/local/src/medooze/mcu/ext
ninja -C out/Release/ common_audio


cd /usr/local/src/medooze/mcu
# Change defaults options
sed -i "s/^\(SANITIZE\s*=\s*\).*\$/\1no/" config.mk
sed -i "s/^\(STATIC\s*=\s*\).*\$/\1no/" config.mk
sed -i "s/^\(VADWEBRTC\s*=\s*\).*\$/\1no/" config.mk

# Change Makefile certificates
# Certificates for DTLS are generated like this: openssl req -nodes -new -x509 -keyout $(BIN)/mcu.key -out $(BIN)/mcu.crt
# Prevent systems to ask for certificates
sed "s|$ORIG_CERT|\ $NEW_CERT|" -i Makefile
make


ldconfig
echo "Creating and starting services"
cd /etc/init.d
wget https://raw.githubusercontent.com/spicyramen/opencall/Development/config/mediamixer
chmod 777 /etc/init.d/mediamixer
update-rc.d mediamixer defaults
/etc/init.d/mediamixer start
check;

echo "Cleaning up"
cd /usr/local/src
rm -rf *.tar.gz
rm -rf *.tgz

echo "Installation completed succesfully!"
