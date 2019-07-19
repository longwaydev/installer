#!/bin/bash
set -x

# edit spark2 and spark2_link according to your situation
spark2=/mnt/d/share/downloads/spark2
spark2_link=http://archive.cloudera.com/spark2/parcels/2.3.0.cloudera3/SPARK2-2.3.0.cloudera3-1.cdh5.13.3.p0.458809-el7.parcel
spark2_csd=SPARK2_ON_YARN-2.3.0.cloudera3.jar

mkdir -p $spark2
spark2_name=`basename "${spark2_link}"`
link_base=${spark2_link%SPARK2*}

# download parcel and manifest.json
[ -f ${spark2}/${spark2_name} ] || wget -P ${spark2}/ ${link_base}${spark2_name}
[ -f ${spark2}/${spark2_name}.sha1 ] || wget -P ${spark2}/ ${link_base}${spark2_name}.sha1
[ -f ${spark2}/manifest.json ] || wget -P ${spark2}/ http://archive.cloudera.com/spark2/csd/${spark2_csd}


