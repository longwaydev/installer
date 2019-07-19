#!/bin/bash

cd splice

./splice_2_install.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

./splice_3_set_properties.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

./splice_4_deploy_client.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1
