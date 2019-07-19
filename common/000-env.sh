#!/bin/bash
#set -e
echo ======================1

current_dir=`pwd`

sed -i 's/\r//' ${current_dir}/../install.properties


echo "current dir" ${current_dir}
while read line; do
    k=${line%=*}
    v=${line#*=}

    case $k in
    "hostnames") HOSTNAMES=$v ;;
    "hostips") IPS=$v ;;
    "root_password") root_password=$v ;;
    "GATEWAY") GATEWAY=$v ;;
    "NETMASK") NETMASK=$v ;;
    *) ;;
    esac
done < ${current_dir}/../install.properties
echo ===========================================2

[ -d /mnt/hgfs/d/packages ] && v=/mnt/hgfs/d/packages
[ -d ${current_dir}/../../packages ] && v=${current_dir}/../../packages
[ -d ${current_dir}/../packages ] && v=${current_dir}/../packages
[ ! -d "$v" ] && v=${v/hgfs/d}
echo '======packages dir::: '"$v"
echo ===========================================3

cd $v
v=`pwd`

downloads=$v
cdh_dir=$v
echo v:::::::::::::"$v"

fs=`ls $v`
for f in $fs
do
    echo 'filepath: '$f
    [[ $f =~ jdk-.* ]] && jdk_gz=$f
    [[ $f =~ mysql-com.* ]] && mysql_rpm=$f
    [[ $f =~ mysql-con.* ]] && mysql_connector=$f
    [[ $f =~ CDH-.*.parcel$ ]] && parcel_name=$f
    [[ $f =~ cloudera.* ]] && cm_name=$f
    if [ $f == 'spark2' ]; then
        spark2_dir=$v/spark2
        sfs=`ls $spark2_dir`
        for sf in $sfs
        do
            echo 'path:' $sf
            [[ $sf =~ .*parcel$ ]] && spark2_parcel=$sf
            [[ $sf =~ SPARK2.*jar$ ]] && spark2_csd=$sf
        done
    fi
    if [ $f == 'splice' ]; then
        splice_dir=$v/splice
        sfs=`ls $splice_dir`
        for sf in $sfs
        do
            echo 'path:' $sf
            [[ $sf =~ .*parcel$ ]] && splice_parcel=$sf
            done
        fi
done
echo ======================================4

HOSTNAME=`hostname --fqdn`

export IPS=(${IPS})
export HOSTNAMES=(${HOSTNAMES})


MASTERNAME=${HOSTNAMES[0]}

export HOSTNAME=$HOSTNAME
export MASTERNAME=$MASTERNAME
export ROOT_PASSWORD=$root_password
export GATEWAY=$GATEWAY
export NETMASK=$NETMASK


var_chk() {
    eval echo $1='${'$1'[@]}'
}
var_chk IPS
var_chk IP
var_chk HOSTNAMES
var_chk HOSTNAME
var_chk MASTERNAME
var_chk spark2_dir
var_chk spark2_parcel
var_chk spark2_csd
var_chk splice_parcel
var_chk splice_dir
var_chk GATEWAY
var_chk NETMASK
var_chk ROOT_PASSWORD
echo ==========================================5

export downloads=$downloads

export jdk_gz=${jdk_gz}
export jdk_version=`echo ${jdk_gz%-linux*} | sed -e 's/-8u/1.8.0_/'`
var_chk jdk_version

export mysql_rpm=${mysql_rpm}
export mysql_connector=${mysql_connector}

export cdh_dir=${cdh_dir}
export parcel_name=${parcel_name}
export cm_name=${cm_name}
export spark2_dir=${spark2_dir}
export spark2_parcel=${spark2_parcel}
export spark2_csd=${spark2_csd}
export splice_dir=${splice_dir}
export splice_parcel=${splice_parcel}
export spark2_version=`echo "${spark2_parcel}" | sed -e 's/^SPARK[^-]*-//' -e 's/-el7.*//' `
export splice_version=`echo "${splice_parcel}" | sed -e 's/^SPLICE[^-]*-//' -e 's/-el7.*//' `
export cm_version=`echo ${cm_name%_x86*} | sed 's/.*cm/cm-/' `
echo =======================================6


filechk() {
    echo "Checking exist: $1 ..."
    if [ "$2" == 'dir' ]; then
        if [ ! -d $1 ]; then echo; echo "Error!  $1 does not exist!"; exit 1; fi
    else
        if [ ! -f $1 ]; then echo; echo "Error!  $1 does not exist!"; exit 1; fi
    fi
}

filechk ${downloads} dir
filechk ${downloads}/${jdk_gz} file
filechk ${downloads}/${mysql_rpm} file
filechk ${downloads}/${mysql_connector}

filechk ${cdh_dir} dir
filechk ${cdh_dir}/${parcel_name} file
filechk ${cdh_dir}/${cm_name} file
filechk ${cdh_dir}/manifest.json file
filechk ${cdh_dir}/${parcel_name}.sha1 file

echo =======================================7

for i in ${!s*} ${!m*} ${!j*} ${!p*} ${!c*} ${!d*} ${!I*} ${!H*} ${!M*}
do
    eval echo $i = "$"$i
done


echo -----------------------------

cd $current_dir
