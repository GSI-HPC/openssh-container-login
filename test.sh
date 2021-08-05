#!/usr/bin/env bash

# change to 2222 if sshd runs on the default port
port=2223

set -x
set -e

command='grep -i pretty /etc/os-release ; ps -p $(echo $PPID) -f --no-headers'


# root login does not launch a container
export SINGULARITY_CONTAINER='foo'
ssh -F ssh-config -p $port root@ssh-container -- "$command"

##
# default container
#

export SINGULARITY_CONTAINER='' # blank environment variable
ssh -F ssh-config -p $port vagrant@ssh-container -- "$command"

export SINGULARITY_CONTAINER=   # empty environment variable
ssh -F ssh-config -p $port vagrant@ssh-container -- "$command"

unset SINGULARITY_CONTAINER     # no environment variable
ssh -F ssh-config -p $port vagrant@ssh-container -- "$command"

echo 0 | ssh -F ssh-config -p $port vagrant@ssh-container -- cat

scp -d -F ssh-config -P $port vagrant@ssh-container:/bin/bash /tmp
scp -d -F ssh-config -P $port /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh -F ssh-config -p $port" /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh -F ssh-config -p $port" vagrant@ssh-container:/bin/bash /tmp

sftp -F ssh-config -P $port vagrant@ssh-container:/bin/bash /tmp
sftp -F ssh-config -P $port vagrant@ssh-container:/tmp <<< $'put /bin/bash'

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif

ssh_options='-F ssh-config -o SendEnv=SINGULARITY_CONTAINER'

ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

echo 0 | ssh $ssh_options -p $port vagrant@ssh-container -- cat

scp -d $ssh_options -P $port vagrant@ssh-container:/bin/bash /tmp
scp -d $ssh_options -P $port /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh $ssh_options -p $port" /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh $ssh_options -p $port" vagrant@ssh-container:/bin/bash /tmp

sftp $ssh_options -P $port vagrant@ssh-container:/bin/bash /tmp
sftp $ssh_options -P $port vagrant@ssh-container:/tmp <<< $'put /bin/bash'

##
# no container
#

export SINGULARITY_CONTAINER=none

ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

echo 0 | ssh $ssh_options -p $port vagrant@ssh-container -- cat
