#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd ~/bf-sde-8.9.1

echo "starting p4 driver: "$APP

./run_switchd.sh -p $APP <$CURRENT/$APP/shell_hw.txt
