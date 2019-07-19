#!/bin/bash
set -e
source ../common/000-env.sh

:<<COMMENT!
echo; echo -------------Begin to install mysql
for((i=0;i<${#IPS[*]};i++)); do
continue
    ssh root@${IPS[$i]} <<SSH!
        rm -f /var/run/yum.pid
        yum remove *mysql*
        #find / -name mysql
        rm -rf /var/lib/mysql
        rm -rf /var/log/mysql.log
    exit
SSH!
done
COMMENT!

rm -f /var/run/yum.pid
yum remove -y *mysql*
#find / -name mysql
rm -rf /var/lib/mysql
rm -rf /var/log/mysql.log

mkdir -p /opt/software
rpm -Uvh  ${downloads}/${mysql_rpm}

yum install -y mysql-server
systemctl start mysqld
systemctl enable mysqld

### Update mysql password
echo; echo "Setting mysql default password 123456 ..."

cat >temp.sql <<EOF
    use mysql
    select host,user,password from user;
    delete from user where user='';
    update user set host='%' where user='localhost';
    update user set password=PASSWORD('123456') where host='%';
    update user set password=PASSWORD('123456') where user='root' and host='localhost';
    update user set password=PASSWORD('123456') where user='root' and host='master';
    grant all privileges on *.* to 'root'@'%' identified by '123456' with grant option;
    flush privileges;
EOF
sed -i -e "s/^\s*//" temp.sql

/usr/bin/expect << EOF
    set timeout 30
    spawn mysql -u root -p -e "source temp.sql"
    expect {
        "*assword*" { send "\r" }
        "YES" { send "\r" }
    }
    expect eof
EOF
rm -f temp.sql

echo ---------------Installation of mysql is complete
echo

