#!/bin/bash
source ../common/000-env.sh
source ../common/functions.sh

#start_cm
cp ../common/json_parser.py ./

echo; echo "==================Update hdf replication .........."
if (( ${#IPS[@]} < 4 )); then
	((count = ${#IPS[@]}-1)) && ((count<1)) && count=1
    cp -f replication.json replication_temp.json
    sed -i "s/count/$count/"  replication_temp.json
    current_dir=`pwd`
    update_product "${current_dir}/replication_temp.json"
   
    sleep 2	
    echo
    deploy_client_config
    sleep 3
    deploy_client_config
    sleep 3
    restart_stale_service
    sleep 3
    restart_stale_service
    sleep 2
    
    echo "Waiting ..."
    sleep 3
    `sudo -u hdfs hadoop  fs -setrep -R -w ${count} /`
    cluster_service restart
    sleep 3
    cluster_service restart
    sleep 5
fi
