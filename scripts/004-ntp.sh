#!/bin/bash
set -e
source ../common/000-env.sh

echo ------------------Begain to install ntp
for((i=0;i<${#IPS[*]};i++));do
    echo; echo "Installing ntp server on ${IPS[$i]} ..."
    ssh root@${IPS[$i]} <<SSHEOF!
    rm -f /var/run/yum.pid
	yum -y install ntp
	exit
SSHEOF!
done

if [ $HOSTNAME == $MASTERNAME ]; then
    echo; echo "Updating master ntp configuration ..."
    sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ d' /etc/ntp.conf
    tee -ia /etc/ntp.conf <<EOF!
    #longdbStart
    restrict default nomodify notrap nopeer noquery
    server 127.127.1.0 fudge 127.127.1.0 stratum 10
    #longdbEnd
EOF!
    sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ s:^\s*::' /etc/ntp.conf
fi

for ((i=1;i<${#IPS[*]};i++)); do
    echo; echo "Set cron update schedule for slave ntp node ${IPS[$i]} ..."
    ssh root@${IPS[$i]} <<EOF!!
        echo "# Run service application" > /etc/cron.d/ntpSyn
        echo "0-59/10 * * * * /usr/sbin/ntpdate ${HOSTNAMES[0]}" >> /etc/cron.d/ntpSyn
    exit
EOF!!
done

for ((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Starting ntp service on ${IPS[$i]} ..."
    ssh root@${IPS[$i]} <<EOFEOF
        service ntpd start
        chkconfig  ntpd on
    exit
EOFEOF
done
echo --------------Installation of ntp is complete
echo



