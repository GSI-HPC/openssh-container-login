#!/usr/bin/env bash

# change to 2222 if sshd runs on the default port
port=2223

set -x
set -e

##
# default container
#

unset SINGULARITY_CONTAINER

ssh -F ssh-config -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'
echo 0 | ssh -F ssh-config -p $port vagrant@ssh-container \
        -- cat

scp -d -F ssh-config -P $port \
        vagrant@ssh-container:/bin/bash /tmp
scp -d -F ssh-config -P $port \
        /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh -F ssh-config -p $port" \
        /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh -F ssh-config -p $port" \
        vagrant@ssh-container:/bin/bash /tmp

sftp -F ssh-config -P $port \
        vagrant@ssh-container:/bin/bash /tmp

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif

ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

echo 0 | ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER vagrant@ssh-container \
        -- cat

scp -d -F ssh-config -P $port -o SendEnv=SINGULARITY_CONTAINER \
        vagrant@ssh-container:/bin/bash /tmp
scp -d -F ssh-config -P $port -o SendEnv=SINGULARITY_CONTAINER \
        /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER" \
        /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER" \
        vagrant@ssh-container:/bin/bash /tmp

##
# no container
#

export SINGULARITY_CONTAINER=none

ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'
echo 0 | ssh -F ssh-config -p $port -o SendEnv=SINGULARITY_CONTAINER vagrant@ssh-container \
        -- cat
