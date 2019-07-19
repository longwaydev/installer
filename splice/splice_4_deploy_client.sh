#!/bin/bash
source /etc/profile
source ../common/000-env.sh
source ../common/functions.sh

HTTP_BASE=http://$HOSTNAME:7180
product=SPLICEMACHINE

start_cm

json=`curl -u admin:admin -s $HTTP_BASE/api/v19/clusters`
clusterName=`echo $json | awk '{tt=$0; sub(".*\"name\"[: \"]+", "",tt); sub("[ :,\"]+\"displayName.*","",tt);  print tt;}'`
echo cluster name: "${clusterName}"

echo ""; echo "Getting hostId......"
URL=${HTTP_BASE}/api/v19/clusters/${clusterName}/hosts
JSON=`curl -u admin:admin -s $URL | xargs `
JSON=`echo $JSON | awk '{ gsub("[-0-9a-zA-Z]+", "\"&\"" , $0); print $0 }'`
echo "JSON============${JSON}"


deploy_cluster_client_config() {
    echo ""; echo "Deploy cluster config......"
    URL=${HTTP_BASE}/api/v19/clusters/${clusterName}/commands/deployClusterClientConfig
    `curl -X POST -u admin:admin -s -o /dev/null -H "Content-Type: application/json" -d "${JSON}" ${URL}`
    #echo "===================res:::${res}"

    for ((i=0;i<=500;i++));do
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
        #      "clientConfigStalenessStatus": "STALE",
        staleState=`echo "$json" | grep 'clientConfigStalenessStatus'`
        #echo "${staleState}"
        staleState=`echo "$json" | grep 'clientConfigStalenessStatus.*STALE'`
        [ -z "${staleState}" ] && break
        echo -n "..."
        sleep 3
        [ $i == 500 ] && echo "Time is out. Please check CM state by web page."
    done
}

restart_cm_1() {
    echo ""; echo "Restart CM service......"
    URL=${HTTP_BASE}/api/v19/cm/service/commands/restart
    `curl -i -X POST -s -o /dev/null -u admin:admin -H "Content-Type: application/json" ${URL}`
    echo "Restarting ......"

    pre_state=
    # "serviceState": "STARTED"
    for ((i=0;i<=500;i++));do
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/cm/service`
	#echo "===$json"
        serviceState=`echo "$json" | sed -e 's/{/{\n/g' -e 's/}/\n}/g' -e 's/,/,\n/g' | grep 'serviceState' \
		| sed -e 's/.*:\s*"//' -e 's/".*//'`
        #serviceState=`echo "${serviceState}" | sed -e 's/.*://' -e 's/[^A-Z]*//g'` | sed -e "$!d"
	#echo "===${serviceState}===${pre_state}==="
        [ "${pre_state}" == "${serviceState}" ] && echo -n "..."
	[ "${pre_state}" != "${serviceState}" ] && echo && echo -n "..." && pre_state=${serviceState}
        
        [ "${serviceState}" == "STARTED" ] && echo && echo "CM is started." && break
        sleep 3 
        [ $i == 500 ] && echo && echo "Time is out. Please check CM state by web page."
    done
}

test() {
        json=`curl -u admin:admin -s ${HTTP_BASE}/api/v19/clusters/${clusterName}/services`
		echo ::::::::::::::${json}
        staleState=`echo "$json" | sed -e 's/{/{\n/g' -e 's/}/\n}/g' -e 's/,/,\n/g'| grep 'STALE'`
        echo ::::::"${staleState}":::
        #staleState=`echo "$json" | grep 'STALE'`
        staleState=`echo "$json" | grep 'clientConfigStalenessStatus.*STALE'`
		echo :::::${staleState}:::
        [ -z "${staleState}" ] && echo "yes"
        echo -n "..."
}

#test

restart_cm_service
deploy_client_config
restart_stale_service

sleep 3
if (( ${#IPS[@]} < 4 )); then
	((count = ${#IPS[@]}-1)) && ((count<1)) && count=1
	`sudo -u hdfs hadoop  fs -setrep -R -w ${count} /`
fi
sleep 3
 
cluster_service start
echo ===================end=======================

