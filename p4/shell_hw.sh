#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd ~/bf-sde-8.9.1

echo "starting p4 shell: "$APP

./run_bfshell.sh -b $CURRENT/$APP/command_hw.py