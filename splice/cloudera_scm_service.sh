#!/bin/bash
set -x
source /etc/profile
source ../common/000-env.sh

current_dir=`pwd`

echo "parameter: $1"

if [ -z $1 ]; then
	echo "Usage \"$0 stop/start/restart\""
	exit
fi

CMD=$1

echo; echo "Restarting agent ..."
for ((i=0;i<${#IPS[*]};i++)); do
	echo "ssh ${IPS[$i]}....."
    ssh root@${IPS[$i]} <<SSHEOF
        /opt/${cm_version}/etc/init.d/cloudera-scm-agent ${CMD}
    exit
SSHEOF
done

echo; echo "Restarting server ..."
/opt/${cm_version}/etc/init.d/cloudera-scm-server  ${CMD}

