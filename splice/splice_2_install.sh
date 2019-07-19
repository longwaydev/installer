#!/bin/bash
source /etc/profile
source ../common/000-env.sh
source ../common/functions.sh

current_dir=`pwd`


restart_stale_cm_service
deploy_client_config
restart_stale_service

echo; echo Installing splice parcel......
cd /opt/cloudera/parcel-repo
for ((i=0;i<10;i++)); do
    if [ ! -e "manifest.json.bak${i}" ]; then
        mv manifest.json manifest.json.bak${i}
        break
    fi
done

cp ${splice_dir}/${splice_parcel} ./
cp ${splice_dir}/${splice_parcel}.sha1 ./${splice_parcel}.sha
cp ${splice_dir}/manifest.json ./


###################################Begin to deploy #############################################
cd ${current_dir}
HTTP_BASE=http://$MASTERNAME:7180/api/v19
product=SPLICEMACHINE

sleep 2
refresh_parcels
#restart_cm
## ============================= Verified that CM server is running ========================================

echo; echo "Check cluster name..."
json=`curl -u admin:admin -s $HTTP_BASE/clusters`
CLUSTER_NAME=`echo $json | awk '{tt=$0; sub(".*\"name\"[: \"]+", "",tt); sub("[ :,\"]+\"displayName.*","",tt);  print tt;}'`
echo cluster name: ${CLUSTER_NAME}
# ================================= Got cluster name =====================================================

cp -f ${current_dir}/../common/json_parser.py ${current_dir}/
splice_info() {
    mkdir -p temp
    #echo splice_version:: ${splice_version}
    curl -u admin:admin -s ${HTTP_BASE}/clusters/${CLUSTER_NAME}/parcels > temp/parcels.json
    SPLICE_INFO=`python -c "import json_parser as jp; print (jp.get_splice_stage('temp/parcels.json','${splice_version}'))"`
    # echo splice_info: $SPLICE_INFO
    SPLICE_STAGE=${SPLICE_INFO%;*}
    # echo splice_stage: $SPLICE_STAGE
    SPLICE_VERSION=${SPLICE_INFO#*;}
    #echo  SPLICE version: $SPLICE_VERSION
}
echo; echo "Getting splice info ..."
splice_info

if [ "${SPLICE_STAGE}" == "DOWNLOADED" ]; then
    echo ""; echo "Start to distribute ......"
    $(curl -u admin:admin -o /dev/null -s -X POST ${HTTP_BASE}/clusters/${CLUSTER_NAME}/parcels/products/$product/versions/${SPLICE_VERSION}/commands/startDistribution)

    for ((i=0;i<=2000;i++));do
        sleep 1
        splice_info

        [ "${SPLICE_STAGE}" != "DOWNLOADED" ] && [ "${SPLICE_STAGE}" != "DISTRIBUTING" ] && break
        echo -n '...'
        if [ $i == 2000 ]; then
            echo 'Distribution is time out. Please check distribution status... '
            exit 1
        fi
    done
fi

if [ "${SPLICE_STAGE}" == "DISTRIBUTED" ]; then
    echo ""; echo "Start to activate ......"
    $(curl -u admin:admin -o /dev/null -s -X POST ${HTTP_BASE}/clusters/${CLUSTER_NAME}/parcels/products/$product/versions/${SPLICE_VERSION}/commands/activate)

    for ((i=0;i<=2000;i++));do
        sleep 1
        splice_info

        [ "${SPLICE_STAGE}" != "DISTRIBUTED" ] && [ "${SPLICE_STAGE}" != "ACTIVATING" ] && break
        echo -n "..."
        if [ $i == 2000 ]; then
            echo 'Activating is time out. Please check activating status... '
            exit 1
        fi
    done
fi
## ==================================== Splice stage: ${SPLICE_STAGE} =====================================================

if [ "${SPLICE_STAGE}" == "ACTIVATED" ]; then
    echo ""; echo "Create directories for splice..."
    sudo -iu hdfs hadoop fs -mkdir -p hdfs:///user/hbase hdfs:///user/splice/history
    sudo -iu hdfs hadoop fs -chown -R hbase:hbase hdfs:///user/hbase hdfs:///user/splice
    sudo -iu hdfs hadoop fs -chmod 1777 hdfs:///user/splice hdfs:///user/splice/history
     #/api/v19/clusters/{clusterName}/commands/stop

    echo ""; echo "Stop cluster..."
    curl -u admin:admin -s -X POST  $HTTP_BASE/clusters/$CLUSTER_NAME/commands/stop

    #data='{"restartOnlyStaleServices":false, "redeployClientConfiguration":true, "restartServiceNames":[]}'/
    #curl -u admin:admin -s -X POST  -H "Content-Type: application/json" -d '${data}' $HTTP_BASE/clusters/$CLUSTER_NAME/commands/restart
    # echo "Stopping cluster, please run splice_3_set_properties.sh."
fi

rm -f ${current_dir}/json_parser.py

