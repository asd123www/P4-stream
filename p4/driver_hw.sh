#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd $SDE

echo "starting p4 driver: "$APP

./run_switchd.sh -p $APP
