#!/bin/bash
#set -x

source ../common/000-env.sh

# Install jdk on all nodes
# -----------------------ssh beginning-----------------------------------------------------
echo -----------Begin to install jdk
for ((i=0;i<${#IPS[*]};i++)); do # Beginning

    # ssh beginning
    echo; echo "Remote ssh ${HOSTNAMES[$i]} ..."
    /usr/bin/expect << EOF
    set timeout 30
    spawn ssh root@${IPS[$i]} "pwd"
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*assword*" { send "${ROOT_PASSWORD}\r" }
        "*#" {send "\r"}
    }
    expect eof
EOF

    ssh root@${IPS[$i]} <<remotessh!
        rm -f /var/run/yum.pid
        yum remove -y *openjdk* # verify if it is removable

        #JAVA
        if [ ! -d /usr/lib/jvm ]; then
            mkdir /usr/lib/jvm
        fi

        tar -zxf ${downloads}/${jdk_gz} -C /usr/lib/jvm/

        JAVA_HOME="/usr/lib/jvm/${jdk_version}"
        alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 1
        alternatives --set java ${JAVA_HOME}/bin/java

        sed -i '/^#java$/,/^#javaEnd$/ d' /etc/profile
        export JAVA_HOME=\${JAVA_HOME}
        echo '#java' >> /etc/profile
        echo "export JAVA_HOME=\${JAVA_HOME}" >> /etc/profile
        echo 'export JRE_HOME=\${JAVA_HOME}/jre' >> /etc/profile
        echo 'export CLASSPATH=.:\${JRE_HOME}/lib/rt.jar:\${JAVA_HOME}/lib/dt.jar:\${JAVA_HOME}/lib/tools.jar' >> /etc/profile
        echo 'export PATH=\${JAVA_HOME}/bin:\${JAVA_HOME}/jre/bin:\$PATH' >> /etc/profile
        echo '#javaEnd' >> /etc/profile

        source /etc/profile
        echo "JAVA_HOME=\$JAVA_HOME"
        echo "PATH=\$PATH"
        echo -n "java version:"
        java -version
        mkdir -p /usr/java
        ln -s \${JAVA_HOME} /usr/java/default
        ln -s \${JAVA_HOME} /usr/java/jdk1.8
        ln -s \${JAVA_HOME} /usr/lib/jvm/j2sdk1.8-oracle
        exit
#ssh end
remotessh!
done
echo -----------Jdk installation is complete
echo
#------------------------------ssh end--------------------------------------------
