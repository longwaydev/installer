#!/bin/bash 
#set -x
source ../common/000-env.sh

### update hosts
sed -i "/^#hadoop$/,/^hadoopEnd$/d" /etc/hosts
echo '#hadoop' >> /etc/hosts
for((i=0;i<${#IPS[*]};i++));
do
    echo "=============="${IPS[$i]}
  echo "${IPS[$i]}  ${HOSTNAMES[$i]}" >> /etc/hosts
done
echo '#hadoopEnd' >> /etc/hosts

### ping to check if other nodes are available
ping_chk(){
    while true
    do
        echo "Checking network $1 ..."
        ping -c 5 -w 50 $1 >& /dev/null
        if [[ $? != "0" ]]; then
            echo " ping fail"
            return 1
        else
            echo " ping ok"
            return 0
        fi
    done
}

set_network() {
    echo "set_network::::"$1"::::::"$2
    # config network
    echo $1 > /etc/hostname
    sed -i "/^HOSTNAME.*/d" /etc/sysconfig/network
    echo "HOSTNAME=$1" >> /etc/sysconfig/network
    #sed -i "s/^HOSTNAME.*/HOSTNAME=$1/" /etc/sysconfig/network
    NETNAME=`ifconfig | sed  '2,$d' | sed 's/:.*//g'`
    network_file=/etc/sysconfig/network-scripts/ifcfg-$NETNAME
    [ -z "${GATEWAY}" ] && GATEWAY=${2%.*}.2
    [ -z "${NETMASK}" ] && NETMASK=255.255.255.0
	
    if [ -f ${network_file} -a -f false ];then
        [ -f ${network_file}_bak ] && cp -f ${network_file}_bak ${network_file}
        [ ! -f ${network_file}_bak ] && cp -f ${network_file} ${network_file}_bak
        sed -i -e 's/BOOTPROTO.*/BOOTPROTO=static/' -e 's/ONBOOT.*/ONBOOT=yes/' ${network_file} 
        echo "IPADDR=$2" >> ${network_file}
        echo "NETMASK=255.255.255.0" >> ${network_file}
        echo "GATEWAY=${2%.*}.2" >> ${network_file}
    else
    cat > /etc/sysconfig/network-scripts/ifcfg-$NETNAME <<EOF
        DEVICE=$NETNAME
        TYPE=Ethernet
        ONBOOT=yes
        NM_CONTROLLED=yes
        BOOTPROTO=static
        IPADDR=$2
        NETMASK=$NETMASK
        GATEWAY=$GATEWAY
        DNS1=8.8.8.8
EOF
    fi

    sed -i 's/^\s*//' /etc/sysconfig/network-scripts/ifcfg-$NETNAME
    hostname $1
}

set_network ${HOSTNAMES[${#IPS[*]}-1]} ${IPS[${#IPS[@]}-1]}
service network restart
sleep 10

for ((i=0;i<${#IPS[*]}-1;i++))
do
    ping_chk ${IPS[$i]}
    if [ $? -ne "0" ]; then
        set_network ${HOSTNAMES[${i}]} ${IPS[${i}]}
        service network restart
        sleep 8
        break
    fi
done

#service network restart

HOSTNAME=`hostname --fqdn`
for((i=0;i<${#IPS[*]};i++)); do
    if [ $HOSTNAME == ${HOSTNAMES[$i]} ]; then IP=${IPS[$i]}; fi
done

# desable firewall
sed -i "s/^SELINUX=.*/SELINUX=disabled/" /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld

echo 'echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.d/rc.local
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.d/rc.local

sleep 10
# ssh config
rm -f /var/run/yum.pid
echo 'installing  ssh'
yum clean all
yum makecache
yum -y install openssh-server initscripts expect

echo 'installing sshd....'
[ -d /root/.ssh ] && rm -r -f /root/.ssh/*
ssh-keygen -t rsa -P ''  -f ~/.ssh/id_rsa \
    && cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys \
    && chmod 700 ~/.ssh/authorized_keys \
    && sed -i 's/^#\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

service sshd start
chkconfig  sshd on

mkdir -p /root/.ssh/temp
if [ $HOSTNAME == ${HOSTNAMES[0]} ]; then mkdir -p '/tmp/ssh'; fi

###################Copy pub key to master #########################
echo Copy pub key ...
# copy all authorized keys to master
if [ $HOSTNAME != ${HOSTNAMES[0]} ]; then
    # copy slave's keys to master
    #./000-ssh-init.sh ${IPS[0]} ${ROOT_PASSWORD}
    /usr/bin/expect << EOF
    set timeout 30
    spawn scp /root/.ssh/id_rsa.pub  root@${IPS[0]}:/tmp/ssh/authorized_keys_$HOSTNAME
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
    }
    expect eof
EOF
else
    cp -f ~/.ssh/id_rsa.pub /tmp/ssh/authorized_keys_$HOSTNAME
fi
echo Copy pub key finished!

[ $HOSTNAME != ${HOSTNAMES[${#IPS[@]}-1]} ] && exit 0

########################Merge all keys#########################################
echo -----------Merge all keys in master
/usr/bin/expect << EOF
    set timeout 30
    spawn ssh root@${IPS[0]}
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
        "*#" { send "\r" }
    }
    expect "*#"
    send "cat /tmp/ssh/authorized_keys_* > /root/.ssh/authorized_keys\r"
    expect "*#"
    send "chmod 700 ~/.ssh/authorized_keys\r"
    expect "*#"
    send "exit\r"
    expect eof
EOF
echo ----------


##############################Copy keys to all slaves##########################
echo ----------Copy merged keys to others
scp_to_slaves() {
    local ip=$1
    echo -- Copy to $ip
    /usr/bin/expect << EOF
    set timeout 30
    spawn ssh root@${IPS[0]}
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
        "*#" { send "\r" }
    }
    send "scp /root/.ssh/authorized_keys root@$ip:/root/.ssh/authorized_keys\r"
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
        "*#" { send "\r" }
    }
     expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
        "*#" { send "\r" }
    }
    expect "*#"
    send "exit\r"
    expect eof
EOF
}

for((i=1;i<${#IPS[@]};i++))
do
    echo "copy to IP::::" ${IPS[$i]}
    scp_to_slaves ${IPS[$i]}
done
echo ---------

##############Verify SSH without password####################
echo ------------ verfy ssh without password
verify_ssh() {
echo ===
local hostname1=$1
local ip1=$2
local ip2=$3
echo "test ssh:::"${hostname1}:::${ip1}:::${ip2}
/usr/bin/expect << EOF
set timeout 30
spawn ssh root@${ip1}
expect {
    "*yes/no*" { send  "yes\r";exp_continue }
    "*assword*" { send  "${ROOT_PASSWORD}\r" }
    "*#" { send "\r" }
}
expect "*#"
send "scp /root/.ssh/authorized_keys root@${ip2}:/root/.ssh/temp/authorized_keys_${hostname1}\r"
expect {
    "*yes/no*" { send  "yes\r";exp_continue }
    "*assword*" { send  "${ROOT_PASSWORD}\r" }
    "*#" { send "\r" }
}
expect "*#"
send "exit\r"
expect eof
EOF
echo ---
}

for((i=0;i<${#IPS[@]};i++))
do
    for ((j=0;j<${#IPS[@]};j++))
    do
        #[ $i == $j ] && continue
        verify_ssh ${HOSTNAMES[$i]} ${IPS[$i]} ${IPS[$j]}
    done
done
echo ---end------


