#!/bin/bash

echo hosts:::$hosts
if [ -z "$hosts" ]; then
   echo The property hosts is required! Please set it in profile.sh.
fi

for ((i=0;i<${#hosts[*]};i++)); do
    HOSTNAMES[$i]=${hosts[$i]%:*}
    IPS[$i]=${hosts[$i]#*:}
done

HOSTNAME=`hostname --fqdn`
MASTERNAME=${HOSTNAMES[0]}

# get IP from HOSTNAME
IP=0
for((i=0;i<${#IPS[*]};i++))
do
  if [ ${HOSTNAMES[$i]} == $HOSTNAME ] ; then
    IP=${IPS[$i]}
  fi
done

if [ "${IP}" != "0" ]; then
    HOSTNAME=$MASTERNAME
    IP=${IPS[0]}
fi

export IPS=${IPS}
export HOSTNAMES=${HOSTNAMES}
export IP=$IP
export HOSTNAME=$HOSTNAME
export MASTERNAME=$MASTERNAME
