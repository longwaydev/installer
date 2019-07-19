#!/bin/bash

[ -z "${IPS}" ] && source 000-env.sh
[ -z "${IPS}" ] && source ../common/000-env.sh

echo '$1:'$1';'
status_check(){
    RETURN=
    local HTTP_BASE=http://$HOSTNAME:7180
    local http_res=`curl -i -s -u admin:admin  $HTTP_BASE/api/v19/clusters`
    local http_code=$(echo ${http_res} | xargs | awk 'NR==1 {print $2}')
    RETURN=${http_code}
}

cm_service(){
    local CMD=$1
     
    echo; echo "$CMD server ..."
    /opt/${cm_version}/etc/init.d/cloudera-scm-server  ${CMD}
    [ $CMD == "restart" ] && return 0 

    echo; echo "$CMD agent ..."
    for ((i=0;i<${#IPS[*]};i++)); do
    	echo "ssh ${IPS[$i]}....."
        ssh root@${IPS[$i]} <<SSHEOF
	    if [ ${CMD} == 'stop' -o ${CMD} == 'restart' ]; then
	        /opt/${cm_version}/etc/init.d/cloudera-scm-agent next_stop_hard
	    fi
            /opt/${cm_version}/etc/init.d/cloudera-scm-agent ${CMD}
        exit
SSHEOF
    done
    
}

restart_cm(){
    cm_service restart 
    sleep 5
    
    echo; echo -n "Checking web status ..."
    for ((i=0;i<=500;i++)); do
	status_check
        local http_code=${RETURN}
        [ "$http_code" == "200" ] && break
        echo -n "..."
        sleep 3
        if [ $i == 500 ]; then
	    echo; echo "Maybe cloudera-scm-server is not started! Time out!"
            return 1
        fi
    done
}


start_cm(){
    cm_service start 
    echo; echo -n "Checking web status ..."
    for ((i=0;i<=500;i++)); do
	status_check
        local http_code=${RETURN}
        [ "$http_code" == "200" ] && break
        echo -n "..."
        sleep 3
        if [ $i == 500 ]; then
	    echo; echo "Maybe cloudera-scm-server is not started! Time out!"
            return 1
        fi
    done
}

get_cluster_name() {
    clusterName=
    local HTTP_BASE=http://$HOSTNAME:7180
    for ((i=0;i<30;i++));do
	local json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters`
	clusterName=`echo $json | awk '{tt=$0; sub(".*\"name\"[: \"]+", "",tt); sub("[ :,\"]+\"displayName.*","",tt);  print tt;}'`
        [ ! -z "${clusterName}" ] && break
	sleep 1
    done
    echo "${clusterName}"
}

cluster_service() {
    local operation=$1
    [ -z "${operation}" ] && operation=start
    [ $operation != "stop" ] && start_cm	
    get_cluster_name
    [ -z "${clusterName}" -a $operation == "stop" ] && return 0
    [ -z "${clusterName}" ] && clusterName=cluster
    local HTTP_BASE=http://$HOSTNAME:7180
    echo ""; echo "${operation} cluster ..."

    echo 'execute:'"curl -u admin:admin -X POST -s -o /dev/null $HTTP_BASE/api/v19/clusters/${clusterName}/commands/${operation}"  
    `curl -u admin:admin -X POST -s -o /dev/null $HTTP_BASE/api/v19/clusters/${clusterName}/commands/${operation}`
    sleep 10

    for ((i=0;i<=500;i++));do
	if (( $i>0 && $i%100 == 0 && $operation == "start" )); then
	    `curl -u admin:admin -X POST -s -o /dev/null $HTTP_BASE/api/v19/clusters/${clusterName}/commands/${operation}`
	    sleep 10
	fi
	[ $operation == "stop" ] && break
	local json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
	local serviceState=`echo "$json" | grep 'serviceState'`
	[ -z "${serviceState}" ] && continue 

	if [ $operation == "stop" ]; then
            local serviceState=`echo "$json" | grep 'serviceState' | sed -e '/STOPPED/d'`
	    echo -n "..."
	    [ -z "${serviceState}" ] && echo -e "\nServices are stopped!" && break
	else
            local serviceState=`echo "$json" | grep 'serviceState' | sed -e '/STARTED/d'`
	    echo -n "..."
	    [ -z "${serviceState}" ] && echo -e "\nServices are started!" && break
	fi
        sleep 3
        [ $i == 500 ] && echo "Time is out. Please check Cluster services status by web page."
    done
}

refresh_parcels(){
    echo; echo "Refresh parcels ......"
    local HTTP_BASE=http://$HOSTNAME:7180
    `curl -u admin:admin -X POST -s -o /dev/null $HTTP_BASE/api/v19/cm/commands/refreshParcelRepos`
    sleep 3
}

deploy_client_config() {
    echo ""; echo "Deploy cluster config......"
    local HTTP_BASE=http://$HOSTNAME:7180
    get_cluster_name
    URL=${HTTP_BASE}/api/v19/clusters/${clusterName}/commands/deployClientConfig
    `curl -X POST -s -o /dev/null -u admin:admin -H "Content-Type: application/json"  ${URL}`
    # echo "===================res:::${res}"

    sleep 5
    local pre_state=
    local serviceState=
    for ((i=0;i<=500;i++));do
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
	serviceState=`echo "$json" | grep 'serviceState' | sed -e '$!d'`
	[ -z "${serviceState}" ] && continue 

	echo serviceState:"$serviceState"

	echo "$json" > /tmp/services.json
	
        staleState=`echo "$json" | grep -e 'clientConfigStalenessStatu.*STALE' | sed -e '$!d'`
	echo "staleState:$staleState"
	
        serviceState=`echo "$json" | grep 'serviceState' | sed -e '/STARTED/d'`
        #echo -n "..."
	#[ -z "${serviceState}" -a -z "${staleState}" ] && echo && echo "Services are started!" && break
	[ -z "${staleState}" ] && echo -e "\nDeploy is finished!" && break
        sleep 3
        [ $i == 500 ] && echo "Time is out. Please check Cluster services state by web page."
    done
}

show_services() {
    echo "show services ..."
    local HTTP_BASE=http://$HOSTNAME:7180
    get_cluster_name 
    echo "cluster Name: ${clusterName}"
    for ((i=0;i<25;i++)); do
        local json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
	[ ! -z "$json" ] && break
	sleep 1
    done
    echo "$json" > /tmp/service.json
    echo "$json"
    local serviceState=`echo "$json" | grep 'serviceState'`
    echo "${serviceState}"
    local staleState=`echo "$json" | grep 'STALE'`
    echo "${staleState}"
}

restart_stale_service() {
    echo "restarting stale service ..."
    local HTTP_BASE=http://$HOSTNAME:7180
    local ts=$(date +%S)
    get_cluster_name
    local json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
    local staleState=`echo "$json" | grep 'STALE'`
    echo ::"${staleState}"

    echo; echo "Restart stale services ..."
    local data='{"restartOnlyStaleServices":true, "redeployClientConfiguration":true}'
    local res=`curl -u admin:admin -s -X POST  -H "Content-Type: application/json" -d "${data}" $HTTP_BASE/api/v19/clusters/${clusterName}/commands/restart`
    sleep 5
    echo response: "${res}"
    echo "Restarting ..."

    for ((i=0;i<=500;i++));do
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
	local serviceState=`echo "$json" | grep 'serviceState'`
	[ -z "$serviceState" ] && continue
        staleState=`echo "$json" | grep 'configStalenessStatus.*STALE'`
	echo "stale State: $staleState"
        [ -z "${staleState}" ] && echo -e "\nStale services are started." && break
	[ ! -z "${staleState}" ] && echo -n "..."
        sleep 3
        [ $i == 500 ] && echo "Time is out. Please check Cluster services by web page."
    done
}


update_product() {
    local fname=$1
    echo "file name:$fname"
    local readonly=$2
    local log=True
    local HTTP_BASE=http://$HOSTNAME:7180
    ts=$(date +%S)
    local old_log_file=/tmp/longdb_properties_${ts}.log
    local log_file=/tmp/longdb_properties_${ts}_new.log
    get_cluster_name
    # product update
    for ((i=0;i<2000;i++));do
        # read item's json string, key, value, url
	local JSON=`python -c "import json_parser as jp; print (jp.get_item('${fname}',$i))"`
        [ ! -z "$log" ] && echo "===JSON===$JSON"
        [ "$JSON" == 'None' ] && echo 'Update is done!' && break

	local URL=`python -c "import json_parser as jp; print (jp.get_url('${fname}',$i))"`
	local VALUE=`python -c "import json_parser as jp; print (jp.get_value('${fname}',$i))"`
	local KEY=`python -c "import json_parser as jp; print (jp.get_key('${fname}',$i))"`
        echo -e "\nUpdating property: ${KEY}"
	[ ! -z "$log" ] && echo "===KEY::${KEY}::VALUE:${VALUE}::URL:${URL}"
	local VALUE=`echo "${VALUE}" | sed "s/  / /g"`

        # read properties' value
	for ((j=0;j<10;j++));do
	    local properties=`curl -s -u admin:admin  ${HTTP_BASE}${URL}`
	    local items=`echo "$properties" | grep "items"`
	    [ ! -z "$items" ] && break
	    sleep 1
	done

	echo -e "\n---------old values:" >> ${log_file}
        echo ${URL} >> ${log_file} 
        #local json_str=$(echo ${properties} | sed 's/^[^{]*{/{/') # split objects
	echo -e "\n"$KEY >> ${old_log_file}
        echo ${properties} >> ${old_log_file} 
	echo -e "\n"$KEY >> ${log_file}
	echo ${properties} >> ${log_file}
	[ ! -z "${readonly}" ] && continue

        # update and check the returned http code
	local return_code=`curl -i -X PUT -u admin:admin  -s -H "Content-Type: application/json" -d "${JSON}" $HTTP_BASE${URL}`

        local http_code=`echo "${return_code}" | sed -e '/^HTTP.*/!d' | sed -e '$!d' | awk 'NR==1 {print $2}'`
        [ "${http_code}" != '200' ] && echo "http_code: ${http_code}" && echo "return_code: ${return_code}"


        # read properties' value
	echo "read new value ..."
	for ((j=0;j<10;j++)); do
	    properties=`curl -s -u admin:admin  ${HTTP_BASE}${URL}`
	    local items=`echo "$properties" | grep "items"`
	    [ ! -z "$items" ] && break
	    sleep 1
	done
	
	echo -e "\n-----------new vaues:" >> ${log_file}
        echo ${URL} >> ${log_file} 
	echo ${properties} > /tmp/splice.json 
	
        local NEW_VALUE=`python -c "import json_parser as jp; print (jp.get_value_by_key('/tmp/splice.json','${KEY}'))"`
        NEW_VALUE=`echo "${NEW_VALUE}" | sed "s/  / /g"`

        # copare new value with expected value, then write log
        if [ "${VALUE}" != "${NEW_VALUE}" ]; then
            echo "Expected Value: ${VALUE}"
            echo "    Real Value: ${NEW_VALUE}"
            echo "=============KEY: ${KEY}::VALUE:${VALUE}::URL:${URL}" >> ${log_file}
            echo "Expected Value ${VALUE}, real value is ${NEW_VALUE}" >> ${log_file}
            exit 1 
        fi
        echo "KEY: ${KEY}" >> ${log_file}
        echo "${VALUE}" >> ${log_file}
    done
}

restart_cm_service () {
    local HTTP_BASE=http://$HOSTNAME:7180
    # product update
    echo ""; echo "Restarting cm service ..."
    local json=`curl -u admin:admin -X POST -s ${HTTP_BASE}/api/v19/cm/service/commands/restart`
    sleep 10
    
    for ((i=0;i<=500;i++));do
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/cm/service`
	local serviceState=`echo "$json" | grep 'serviceState'`
	[ -z "$serviceState" ] && continue
	local staleState=`echo "$json" | grep 'configStalenessStatus.*STALE'`
	echo "stale State: $staleState"
        [ -z "${staleState}" ] && echo -e "\nStale services are started." && break
	[ ! -z "${staleState}" ] && echo -n "..."
        sleep 3
        [ $i == 500 ] && echo "Time is out. Please check cloudera manager service by web page."
    done
}

restart_stale_cm_service() {
    echo "Restarting stale cloudera manager service ..."
    local HTTP_BASE=http://$HOSTNAME:7180
    for ((i=0;i<=100;i++));do
        local json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/cm/service`
	local serviceState=`echo "$json" | grep 'serviceState'`
	echo "$serviceState"
	[ ! -z "$serviceState" ] && break 
	sleep 3
	(( $i==100)) && return 0
    done
    local staleState=`echo "$json" | grep 'configStalenessStatus.*STALE'`
    echo "$staleState"
    [ ! -z "$staleState" ] && restart_cm_service
}
[ $1 == "restart_stale_cm_service" ] && restart_stale_cm_service


hard_stop() {
    cluster_service stop
    sleep 50
    echo "Waiting..."
    cm_service stop
}


if [ $1 == "hard_stop" ]; then
    hard_stop
fi

if [ $1 == "status" -o $1 == "status_cm" ]; then
    cm_service status
fi

if [ $1 == "stop" -o $1 == "stop_cm" ]; then
    cm_service stop
fi

if [ $1 == "start" -o $1 == "start_cm" ]; then
    cm_service start 
fi

if [ $1 == "restart" -o $1 == "restart_cm" ]; then
    cm_service restart 
fi

if [ $1 == "start_all" ]; then
   cluster_service start
fi

if [ $1 == "restart_cluster" -o $1 == "cluster_restart" ]; then
   cluster_service restart
fi

if [ $1 == "stop_cluster" -o $1 == "cluster_stop" ]; then
   cluster_service stop
fi

if [ $1 == "show_services" ]; then
   show_services
fi

if [ $1 == "deploy_client_config" ] ; then
    deploy_client_config
fi
if [ $1 == "restart_stale_service" ]; then
    restart_stale_service
fi
