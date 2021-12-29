#!/bin/bash
cd `dirname $0`
CURRENT=`pwd`
APP=$1

echo "compling p4 project: "$CURRENT/$APP/$APP.p4

API=$CURRENT/API
common_p4=$CURRENT/common_p4

. ~/tools/p4_build.sh  $CURRENT/$APP/$APP.p4 \
    -- P4_NAME=$APP \
    P4FLAGS="--no-dead-code-elimination" \
    P4PPFLAGS="-I ${API} -I ${common_p4}"
