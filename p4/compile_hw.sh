#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd $CURRENT
NAME=`basename "$CURRENT"`

API=$CURRENT/API
common_p4=$CURRENT/common_p4

echo "compling p4 project: "$CURRENT/$APP/$APP.p4

. ~/tools/p4_build.sh  $CURRENT/$APP/$APP.p4 \
    --with-p4c=bf-p4c \
    P4_NAME=$APP \
    P4FLAGS="--create-graphs --no-dead-code-elimination" \
    P4_VERSION=p4_16 \
    P4PPFLAGS="-I ${API} -I ${common_p4}" 
