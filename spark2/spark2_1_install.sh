#!/bin/bash


source /etc/profile
source ../common/000-env.sh
source ../common/functions.sh

start_cm
current_dir=`pwd`
echo ""; echo "Copy files ..."
[ ! -d /opt/cloudera/csd ] && mkdir /opt/cloudera/csd
cd /opt/cloudera/csd
cp ${spark2_dir}/${spark2_csd} ./
chown cloudera-scm:cloudera-scm ${spark2_csd}

echo; echo "Backup old manifest.json ... "
cd /opt/cloudera/parcel-repo
for ((i=0;i<10;i++)); do
    if [ ! -f "manifest.json.bak${i}" ]; then
        mv manifest.json manifest.json.bak${i}
        break
    fi
done

echo; echo "Copy parcels ..."
cp ${spark2_dir}/${spark2_parcel} ./
cp ${spark2_dir}/${spark2_parcel}.sha1 ./${spark2_parcel}.sha
cp ${spark2_dir}/manifest.json ./

cd ${current_dir}
http_base=http://${MASTERNAME}:7180/api/v19
product=SPARK2

refresh_parcels


