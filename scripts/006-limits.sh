#!/bin/bash
set -e
source ../common/000-env.sh

echo ---------------Begin to update limits.conf
for((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Updating limits.conf on ${IPS[$i]} ..."
    ssh root@${IPS[$i]} <<SSH!
        sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ d' /etc/security/limits.conf
        tee -ia /etc/security/limits.conf <<EOF
            #longdbStart
            *               soft    nofile          65535
            *               hard    nofile          1029345
            *               soft    nproc           unlimited
            *               hard    nproc           unlimited
            *               soft    memlock         unlimited
            *               hard    memlock         unlimited
           #longdbEnd
EOF
        sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ s:^\s*::' /etc/security/limits.conf
    exit
SSH!
done

echo --------------Update of limits.conf is complete
echo


