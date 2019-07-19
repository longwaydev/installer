#!/bin/bash
set -x

# edit splice_dir and splice_link according to your situation
splice_dir=splice_parcel
splice_link=https://s3.amazonaws.com/splice-releases/2.7.0.1833/cluster/parcel/cdh5.14.0/SPLICEMACHINE-2.7.0.1833.cdh5.14.0.p0.138-el7.parcel

mkdir -p $splice_dir
splice_name=`basename "${splice_link}"`
link_base=${splice_link%SPLICE*}

# download parcel and manifest.json
wget -P ${splice_dir}/ ${link_base}${splice_name}
wget -P ${splice_dir}/ ${link_base}manifest.json

# Generate parcel.sha1
row=$(cat ${splice_dir}/manifest.json | awk '{i=index($0, "'${splice_name}'");if (i>0) print NR}')
((row-=2))
hash=$(cat ${splice_dir}/manifest.json | awk 'NR=="'${row}'"{gsub(".*:[^a-z0-9]*|[^0-9a-z]+", "", $0); print $0}')
echo "$hash" > ${splice_dir}/${splice_name}.sha1


