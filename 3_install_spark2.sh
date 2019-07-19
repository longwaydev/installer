#!/bin/bash

cd spark2

./spark2_1_install.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

./spark2_2_deploy.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

echo "Please add spark service on Cloudera web manager."
