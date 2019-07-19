#!/bin/bash
#set -e
source ../common/000-env.sh

echo
echo ---------------Begin to install mysql connector
for((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Installing mysql connector on ${IPS[$i]} ..."
    ssh root@${IPS[$i]} "mkdir -p /opt/software"

    scp root@${IPS[0]}:${downloads}/${mysql_connector} "root@${IPS[$i]}:/opt/software/"
    ssh root@${IPS[$i]} <<SSH!!
        # config mysql java driver
        mkdir -p /usr/share/java
        mkdir -p /opt/cm-5.14.0/share/cmf/lib
        cd /opt/software
        tar -zxf /opt/software/${mysql_connector}
        mysql_connector_name=`basename ${mysql_connector} .tar.gz`
        echo  ============\${mysql_connector_name}
        cp /opt/software/\${mysql_connector_name}/\${mysql_connector_name}-bin.jar /usr/share/java/
        ln -sf /usr/share/java/\${mysql_connector_name}-bin.jar /usr/share/java/mysql-connector-java.jar
	rm -rf /opt/software/mysql*
    exit
SSH!!
done
echo -----------------Installation of mysql connector is complete.
echo

echo
echo ---------------Begin to make metadata database

sql_code=$(cat <<EOF
#   create database scm default character set utf8 default collate utf8_general_ci;
#   grant all on scm.* to 'scm'@'%' identified by '123456';

    create database amon default character set utf8 default collate utf8_general_ci;
    grant all on amon.* to 'amon'@'%' identified by '123456';

    create database rman default character set utf8 default collate utf8_general_ci;
    grant all on rman.* to 'rman'@'%' identified by '123456';

    create database hue default character set utf8 default collate utf8_general_ci;
    grant all on hue.* to 'hue'@'%' identified by '123456';

    create database metastore default character set utf8 default collate utf8_general_ci;
    grant all on metastore.* to 'hive'@'%' identified by '123456';

    create database nav default character set utf8 default collate utf8_general_ci;
    grant all on nav.* to 'nav'@'%' identified by '123456';

    create database navms default character set utf8 default collate utf8_general_ci;
    grant all on navms.* to 'navms'@'%' identified by '123456';

    create database oozie default character set utf8 default collate utf8_general_ci;
    grant all on oozie.* to 'oozie'@'%' identified by '123456';

    flush privileges;
EOF
); sql_code=`echo "${sql_code}" | sed -e "s/^\s*//"`

echo; echo -e "Running sql ..."
echo "${sql_code}" | mysql -u root -p123456

echo --------------------Making metadata database is complete.
echo


