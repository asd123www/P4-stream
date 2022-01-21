#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd $SDE

echo "starting p4 shell: "$APP

./run_bfshell.sh -f $CURRENT/$APP/shell_hw.txt
# ./run_bfshell.sh -b $CURRENT/$APP/command_hw.py
