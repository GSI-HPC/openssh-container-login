#!/usr/bin/env bash

# change to 2222 if sshd runs on the default port
port=2223

#set -x
set -e

# identify the login environment...
command='grep -i pretty /etc/os-release ; ps -p $(echo $PPID) -f --no-headers'

# do not propagate the SINGULARITY_CONTAINER environment variable
ssh -F ssh-config -p $port root@ssh-container -- "$command"

# enable debugging of the login script
export SSHD_CONTAINER_DEBUG=true

# use the Vagrant ssh configuration and enable propagation
# of the SINGULARITY_CONTAINER environment varibale
ssh_options='-F ssh-config -o SendEnv=SINGULARITY_CONTAINER -o SendEnv=SSHD_CONTAINER_DEBUG'

# root login does not launch a container
ssh $ssh_options -p $port root@ssh-container -- "$command"

# non existing container
export SINGULARITY_CONTAINER='foo'
ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

##
# default container
#

export SINGULARITY_CONTAINER='' # blank environment variable
ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

export SINGULARITY_CONTAINER=   # empty environment variable
ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

unset SINGULARITY_CONTAINER     # no environment variable
ssh $ssh_options -p $port vagrant@ssh-container -- "$command"

echo 0 | ssh $ssh_options -p $port vagrant@ssh-container -- cat

scp -d $ssh_options -P $port vagrant@ssh-container:/bin/bash /tmp
scp -d $ssh_options -P $port /bin/bash vagrant@ssh-container:/tmp

rsync -v -e "ssh $ssh_options -p $port" /bin/bash vagrant@ssh-container:/tmp
rsync -v -e "ssh $ssh_options -p $port" vagrant@ssh-container:/bin/bash /tmp

sftp $ssh_options -P $port vagrant@ssh-container:/bin/bash /tmp
sftp $ssh_options -P $port vagrant@ssh-container:/tmp <<< $'put /bin/bash'

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif


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


