#!/bin/bash
export SDE=~/bf-sde-9.6.0
export SDE_INSTALL=$SDE/install
export PATH=$SDE_INSTALL/bin:$PATH

cd `dirname $0`
CURRENT=`pwd`
APP=$1

cd ~/bf-sde-9.6.0
. ~/tools/set_sde.bash

echo "starting p4 model: "$APP

sudo $SDE_INSTALL/bin/veth_setup.sh
./run_tofino_model.sh -p $APP
