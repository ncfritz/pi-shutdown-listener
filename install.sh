#!/bin/sh

if [ "$(id -u)" != "0" ]; then
   echo "Installer must be run as root" 1>&2
   exit 1
fi

SOURCE="$0"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

pip install -r $DIR/requirements.txt > /tmp/pi-shutdown-listener-pip.log 2>&1

if [ $? != 0 ]; then
    echo "Failed to install python dependencies" 1>&2
    exit 1
fi

LISTENER_ROOT=/usr/local/pi-shutdown-listener

if [ -d "$LISTENER_ROOT" ]; then
    echo "Cleaning up previous install..."

    rm -rf $LISTENER_ROOT/bin > /dev/null 2>&1
    rm -rf $LISTENER_ROOT/lib > /dev/null 2>&1
    rm /lib/systemd/system/pi-shutdown-listener.service > /dev/null 2>&1
fi

mkdir -p $LISTENER_ROOT > /dev/null 2>&1
mkdir -p $LISTENER_ROOT/bin > /dev/null 2>&1
mkdir -p $LISTENER_ROOT/lib > /dev/null 2>&1
mkdir -p $LISTENER_ROOT/etc > /dev/null 2>&1

cp $DIR/bin/* $LISTENER_ROOT/bin
cp $DIR/lib/* $LISTENER_ROOT/lib
cp $DIR/etc/* $LISTENER_ROOT/etc
cp $DIR/pi-shutdown-listener.service /lib/systemd/system/pi-shutdown-listener.service