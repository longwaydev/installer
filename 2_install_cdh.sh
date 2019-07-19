#!/bin/bash

current_dir=`pwd`
cd scripts

### Install jdk on all nodes
./003-jdk.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### Install ntp on all nodes
./004-ntp.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### update file: sysctl.cfg
./005-sysctl.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### update file: limits.cfg
./006-limits.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### Install mysql server
./007-mysql.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### Install mysql connector
./008-mysql-jdbc.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

### Install cloudera manager
./009-cm.sh
[ $? == 1 ] && echo "Error happens! Please check!" && exit 1

