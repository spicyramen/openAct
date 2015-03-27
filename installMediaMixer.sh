#!/bin/bash
#
# Program: Install MCU mixer in Ubuntu 12.04
# Author: Gonzalo Gasca Meza <gonzalo@cloudtree.io>
# This program is distributed under the terms of the GNU Public License V2

trap "rm .f 2> /dev/null; exit" 0 1 3
# Initialize our own variables:

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
 
svn checkout svn://svn.code.sf.net/p/mcumediaserver/code/trunk medooze
svn checkout http://mp4v2.googlecode.com/svn/trunk/ mp4v2
git clone git://git.videolan.org/ffmpeg.git
git clone git://git.videolan.org/x264.git
git clone http://git.chromium.org/webm/libvpx.git
git clone https://github.com/cisco/libsrtp

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

sed -i "s/^\(SANITIZE\s*=\s*\).*\$/\1no/" config.mk
sed -i "s/^\(STATIC\s*=\s*\).*\$/\1no/" config.mk
sed -i "s/^\(VADWEBRTC\s*=\s*\).*\$/\1no/" config.mk

ldconfig
cd /etc/init.d
wget https://raw.githubusercontent.com/spicyramen/opencall/Development/config/mediamixer
chmod 777 /etc/init.d/mediamixer
update-rc.d mediamixer defaults
/etc/init.d/mediamixer start

echo "Cleaning up"
cd /usr/local/src
rm -rf *.tar.gz
rm -rf *.tgz

