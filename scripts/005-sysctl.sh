#!/bin/bash
set -e
source ../common/000-env.sh

echo --------------Begin to update sysctl.cfg
for((i=0;i<${#IPS[*]};i++)); do
    echo; echo "Updating sysctl.conf on ${IPS[$i]} ..."
    ssh root@${IPS[$i]} <<SSH!
    sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ d' /etc/sysctl.conf
    tee -ia /etc/sysctl.conf <<EOF
        #longdbStart
        kernel.sysrq = 0
        kernel.core_uses_pid = 1
        kernel.msgmnb = 65536
        kernel.msgmax = 65536
        kernel.shmmax = 68719476736
        kernel.shmall = 4294967296
        ##打开文件数参数(20*1024*1024)
        fs.file-max= 20971520
        ##WEB Server参数
        net.ipv4.tcp_tw_reuse=1
        net.ipv4.tcp_tw_recycle=1
        net.ipv4.tcp_fin_timeout=30
        net.ipv4.tcp_keepalive_time=1200
        net.ipv4.ip_local_port_range = 1024 65535
        net.ipv4.tcp_rmem=4096 87380 8388608
        net.ipv4.tcp_wmem=4096 87380 8388608
        net.ipv4.tcp_max_syn_backlog=8192
        net.ipv4.tcp_max_tw_buckets = 5000
        ##TCP补充参数
        net.ipv4.ip_forward = 0
        net.ipv4.conf.default.rp_filter = 1
        net.ipv4.conf.default.accept_source_route = 0
        net.ipv4.tcp_syncookies = 1
        net.ipv4.tcp_sack = 1
        net.ipv4.tcp_window_scaling = 1
        net.core.wmem_default = 8388608
        net.core.rmem_default = 8388608
        net.core.rmem_max = 16777216
        net.core.wmem_max = 16777216
        net.core.netdev_max_backlog = 262144
        net.ipv4.tcp_max_orphans = 3276800
        net.ipv4.tcp_timestamps = 0
        net.ipv4.tcp_synack_retries = 1
        net.ipv4.tcp_syn_retries = 1
        net.ipv4.tcp_mem = 94500000 915000000 927000000
        ##禁用ipv6
        net.ipv6.conf.all.disable_ipv6 =1
        net.ipv6.conf.default.disable_ipv6 =1
        ##swap使用率优化
        vm.swappiness=10
        #longdbEnd
EOF
    sed -i '/^\s*#longdbStart$/,/^\s*#longdbEnd$/ s:^\s*::' /etc/sysctl.conf
    exit
SSH!
done

echo ------------Updating of sysctl.cfg is complete
echo


