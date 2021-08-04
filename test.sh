#!/usr/bin/env bash

# change to 2222 if sshd runs on the default port
port=2223

set -x
set -e

##
# default container
#

# blank environment variable
export SINGULARITY_CONTAINER=''
ssh -F ssh-config -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

# empty environment variable
export SINGULARITY_CONTAINER=
ssh -F ssh-config -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

# no environment variable
unset SINGULARITY_CONTAINER
ssh -F ssh-config -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

# standard input stream
echo 'text from stdin' |\
ssh -F ssh-config -p $port vagrant@ssh-container \
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
sftp -F ssh-config -P $port \
        vagrant@ssh-container:/tmp <<< $'put /bin/bash'

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif

ssh_options='-F ssh-config -o SendEnv=SINGULARITY_CONTAINER'

ssh $ssh_options -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

echo 'text from stdin' |\
ssh $ssh_options -p $port vagrant@ssh-container \
        -- cat

scp -d $ssh_options -P $port \
        vagrant@ssh-container:/bin/bash /tmp
scp -d $ssh_options -P $port \
        /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh $ssh_options -p $port" \
        /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh $ssh_options -p $port" \
        vagrant@ssh-container:/bin/bash /tmp

sftp $ssh_options -P $port \
        vagrant@ssh-container:/bin/bash /tmp
sftp $ssh_options -P $port \
        vagrant@ssh-container:/tmp <<< $'put /bin/bash'

##
# no container
#

export SINGULARITY_CONTAINER=none

ssh $ssh_options -p $port vagrant@ssh-container \
        -- 'grep -i pretty /etc/os-release ; ps -u $USER -fH'

echo 'text from stdin' |\
ssh $ssh_options -p $port vagrant@ssh-container \
        -- cat
