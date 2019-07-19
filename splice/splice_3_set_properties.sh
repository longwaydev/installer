#!/bin/bash

#set -x 

source /etc/profile
source ../common/000-env.sh
source ../common/functions.sh

readonly=$1
current_dir=`pwd`

HTTP_BASE=http://$MASTERNAME:7180
product=SPLICEMACHINE

skips=nothing
#skips="hbase_regionserver_java_heapsize hbase_master_java_heapsize"
MEM=(`cat /proc/meminfo | grep MemTotal | sed -e "s/MemTotal:\s*//" -e "s/\s*kB//"`)
(( $MEM > 40000000  )) && skips=nothing

#start_cm
#[ $? == 1 ] && echo  "CM server is not running. Please check!" && exit 1

rm -f /tmp/splice.json
rm -f /tmp/splice.log
splice_old=/tmp/splice_$(date +%Y%m%d%H%M%S).log

cp ${current_dir}/../common/json_parser.py  ${current_dir}/

echo; echo "========================Updating CM service properties ......"
update_product put/mgmt.json

echo ""; echo "========================Updating zookeeper properties ......"
update_product put/zookeeper.json

echo ""; echo "========================Updating hdfs properties ......"
update_product put/hdfs.json

echo ""; echo "========================Updating habse properties ......"
update_product put/hbase.json

echo ""; echo "========================Updating yarn properties ......"
update_product put/yarn.json
update_product put/yarn_append.json append

echo ""; echo "========================Modify Authentication Mechanism ........"
echo "If you're enabling Kerberos, you need to add this option to your HBase Master Java Configuration Options:\
    -Dsplice.spark.hadoop.fs.hdfs.impl.disable.cache=true"
read -p "Do you add this option? [y/N] " option
if [ "${option}" == "y" -o "${option}" == "yes" -o "${option}" == "Y" -o "${option}" == "Yes" ]; then
    update_product put/auth.json
fi

echo ; echo "========================Update log location ........"
echo "Splice Machine logs all SQL statements by default, storing the log entries in your region server's logs,\
 as described in our Using Logging topic. You can modify where Splice Machine stroes logs by modifying \
  your RegionServer Logging Advanced Configuration Snippet (Safety Valve) section of your HBase Configuration."
read -p "Do you modify the log location? [y/N] " modify
if [ "${modify}" == "y" -o "${modify}" == 'Y' -o "${modify}" == "yes" -o "${modify}" == "Yes" ]; then
    update_product put/log_location.json
fi

echo ""; echo "========================Update all properties ........"
update_product put/all.json

echo; echo "==================Update hdf replication .........."
if (( ${#IPS[@]} < 4 )); then
	((count = ${#IPS[@]}-1)) && ((count<1)) && count=1
    cp ./put/replication.json ./put/replication_temp.json
    sed -i "s/count/$count/"  ./put/replication_temp.json
    update_product put/replication_temp.json
fi

rm -f ${current_dir}/json_parser.json

