#!/bin/bash

source /etc/profile
source ../common/000-env.sh
source ../common/functions.sh

current_dir=`pwd`

cd ${current_dir}
http_base=http://${MASTERNAME}:7180/api/v19
product=SPARK2

#restart_cm
sleep 3
### ============================= Verified that CM server is running ========================================
get_cluster_name
#json=`curl -u admin:admin -s ${http_base}/clusters`
#cluster_name=`echo ${json} | awk '{tt=$0; sub(".*\"name\"[: \"]+", "",tt); sub("[ :,\"]+\"displayName.*","",tt);  print tt;}'`
#echo cluster name: ${cluster_name}
# ================================= Got cluster name =====================================================

cp -f ${current_dir}/../common/json_parser.py ./
spark2_info() {
    echo "get parces infomation: "
    mkdir -p temp
    #echo spark2_version:: ${spark2_version}
    for ((i=0;i<20;i++));do
        local json=`curl -u admin:admin -s ${http_base}/clusters/${cluster_name}/parcels`
	[ -z "$json" ] && sleep 1 && continue
	break
    done
    #echo "json: $json"
    echo "$json" > /tmp/parcels.json
    spark2_info=`python -c "import json_parser as jp; print (jp.get_spark2_stage('/tmp/parcels.json','${spark2_version}'))"`
    echo spark2_info: ${spark2_info}
    spark2_stage=${spark2_info%;*}
    echo spark2_stage: ${spark2_stage}
    spark2_version=${spark2_info#*;}
    echo  SPARK2 version: ${spark2_version}
}
spark2_info

if [ "${spark2_stage}" == "DOWNLOADED" ]; then
    echo ""; echo "Start to distribute ......"
    $(curl -u admin:admin -o /dev/null -s -X POST ${http_base}/clusters/${cluster_name}/parcels/products/${product}/versions/${spark2_version}/commands/startDistribution)

    for ((i=0;i<=500;i++));do
        sleep 3
        spark2_info

        [ "${spark2_stage}" != "DOWNLOADED" ] && [ "${spark2_stage}" != "DISTRIBUTING" ] && echo && break
        echo -n '...'
        if [ $i == 500 ]; then
            echo 'Distribution is time out. Please check distribution status... '
            exit 1
        fi
    done
fi

if [ "${spark2_stage}" == "DISTRIBUTED" ]; then
    echo ""; echo "Start to activate ......"
    $(curl -u admin:admin -o /dev/null -s -X POST ${http_base}/clusters/${cluster_name}/parcels/products/${product}/versions/${spark2_version}/commands/activate)

    for ((i=0;i<=500;i++));do
        sleep 3
        spark2_info

        [ "${spark2_stage}" != "DISTRIBUTED" ] && [ "${spark2_stage}" != "ACTIVATING" ] && echo && break
        echo -n '...'
        if [ $i == 500 ]; then
            echo 'Activating is time out. Please check activating status... '
            exit 1
        fi
    done
fi
# ==================================== Splice stage: activated =====================================================

if [ "${spark2_stage}" == "ACTIVATED" ]; then
	restart_cm
fi
rm -f ${current_dir}/json_parser.py
exit 0





