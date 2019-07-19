#!/bin/bash
source /etc/profile
source ../common/000-env.sh
source /etc/rc.d/rc.local

echo; echo 'Begin unzip cm ...'
if [ ! -f /opt/${cm_version}/etc/cloudera-scm-agent/config.ini ]; then
    tar -xzf ${cdh_dir}/${cm_name} -C /opt/
    sed -i "s/^server_host.*/server_host=$MASTERNAME/" /opt/${cm_version}/etc/cloudera-scm-agent/config.ini
fi

#all nodes
echo; echo "Adding user cloudera-scm ..."
for((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Add cloudera-scm on ${IPS[$i]} ......"
    ssh root@${IPS[$i]} <<SSH!
       echo never > /sys/kernel/mm/transparent_hugepage/defrag
       echo never > /sys/kernel/mm/transparent_hugepage/enabled

       cloudera_user=`grep "cloudera-scm" /etc/passwd`
        if [ -z "${cloudera_user}" ];then
            echo "..."
            useradd --system --home-dir /opt/${cm_version}/run/cloudera-scm-server --no-create-home --shell=/bin/false --comment 'Cloudera SCM User' cloudera-scm
            systemctl stop firewalld
            systemctl disable firewalld
        else
            echo  "user is already existed!"
        fi
    exit
SSH!
done

## mysql -u root -p123456 "drop database scm;"

echo; echo "Running scm_prepare_database.sh ......"
script /tmp/mysql.log -c "mysql -u root -p123456 -e 'use scm;'"
db_test=`grep "Unknown database" /tmp/mysql.log`
echo "====db_test::::${db_test}"
if [ ! -z "${db_test}" ]; then
    echo "Adding scm database ..."
    /opt/${cm_version}/share/cmf/schema/scm_prepare_database.sh mysql scm -hlocalhost -uroot -p123456 --scm-host localhost scm scm scm
else
    echo "scm data is already existed!"
fi


# copy to slaves
echo; echo "Coping cm directory to other nodes ......"
for((i=1;i<${#IPS[*]};i++)); do
    echo "Coping to ${IPS[$i]}..."
    `scp -r /opt/${cm_version} root@${IPS[$i]}:/opt/`
    echo "scp is finished"; echo
done

## only on master
echo; echo "Copy cm parcel to parcel-repo ......"
mkdir -p /opt/cloudera/parcel-repo
cp ${cdh_dir}/${parcel_name} /opt/cloudera/parcel-repo/
cp ${cdh_dir}/${parcel_name}.sha1 /opt/cloudera/parcel-repo/
cp ${cdh_dir}/manifest.json /opt/cloudera/parcel-repo/
mv /opt/cloudera/parcel-repo/${parcel_name}.sha1 /opt/cloudera/parcel-repo/${parcel_name}.sha

## install dependencies on all nodes
for((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Installing all dependencies on ${IPS[$i]} ......"
    ssh root@${IPS[$i]} <<SSH!
        rm -f /var/run/yum.pid
        yum -y -q install chkconfig python bind-utils psmisc libxslt zlib sqlite cyrus-sasl-plain cyrus-sasl-gssapi fuse fuse-libs redhat-lsb  portmap mod_ssl openssl-devel python-psycopg2 MySQL-python
        exit
SSH!
done

#on master
echo; echo "Starting cloudera-scm-server ......"
/opt/${cm_version}/etc/init.d/cloudera-scm-server start

sleep 5
echo; echo "Starting cloudera-scm-agent ......"
/opt/${cm_version}/etc/init.d/cloudera-scm-agent start

# on slaves
for((i=1;i<${#IPS[*]};i++)); do
    echo; echo "Starting cloudera-scm-agent on ${IPS[$i]} ......"
    ssh root@${IPS[$i]} <<SSH!!!
        /opt/${cm_version}/etc/init.d/cloudera-scm-agent start
        exit
SSH!!!
done

echo "waiting ..."
sleep 20
sysctl vm.swappiness=10

echo '------------------------end--------------------------------------'

