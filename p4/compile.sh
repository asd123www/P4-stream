#!/bin/bash
export SDE=~/bf-sde-9.6.0
export SDE_INSTALL=$SDE/install
export PATH=$SDE_INSTALL/bin:$PATH

cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd ~/bf-sde-9.6.0
. ~/tools/set_sde.bash

cd $CURRENT
NAME=`basename "$CURRENT"`

echo "compling p4 project: "$CURRENT/$APP/$APP.p4

API=$CURRENT/API
common_p4=$CURRENT/common_p4

./p4_build.sh  $CURRENT/$APP/$APP.p4 --with-p4c=bf-p4c \
    -- P4_NAME=$APP \
    P4FLAGS="--no-dead-code-elimination" \
    P4PPFLAGS="-I ${API} -I ${common_p4}"
