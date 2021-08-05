#!/usr/bin/env bash

run() {
        echo SSHD_CONTAINER_DEBUG=$SSHD_CONTAINER_DEBUG
        echo SINGULARITY_CONTAINER=$SINGULARITY_CONTAINER
        echo $@
        echo ---------
        eval "$@"
        echo
}

# change to 2222 if sshd runs on the default port
port=2223
box=centos7-test

# stop on a command failing
set -e

# identify the login environment...
command='grep -i pretty /etc/os-release ; ps -p $(echo $PPID) -f --no-headers'

# do not propagate the SINGULARITY_CONTAINER environment variable
run "ssh -F ssh-config -p $port root@$box -- '$command'"

# enable debugging of the login script
export SSHD_CONTAINER_DEBUG=true

# use the Vagrant ssh configuration and enable propagation
# of the SINGULARITY_CONTAINER environment varibale
ssh_options='-F ssh-config -o SendEnv=SINGULARITY_CONTAINER -o SendEnv=SSHD_CONTAINER_DEBUG'

# root login does not launch a container
run "ssh $ssh_options -p $port root@$box -- '$command'"

# non existing container
export SINGULARITY_CONTAINER='foo'
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"

##
# default container
#

export SINGULARITY_CONTAINER='' # blank environment variable
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"
export SINGULARITY_CONTAINER=   # empty environment variable
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"
unset SINGULARITY_CONTAINER     # no environment variable
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"
run "echo 0 | ssh $ssh_options -p $port vagrant@$box -- cat"
run "scp -d $ssh_options -P $port vagrant@$box:/bin/bash /tmp"
run "scp -d $ssh_options -P $port /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options -p $port' /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options -p $port' vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options -P $port vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options -P $port vagrant@$box:/tmp <<< $'put /bin/bash'"

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"
run "echo 0 | ssh $ssh_options -p $port vagrant@$box -- cat"
run "scp -d $ssh_options -P $port vagrant@$box:/bin/bash /tmp"
run "scp -d $ssh_options -P $port /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options -p $port' /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options -p $port' vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options -P $port vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options -P $port vagrant@$box:/tmp <<< $'put /bin/bash'"

##
# no container
#

export SINGULARITY_CONTAINER=none
run "ssh $ssh_options -p $port vagrant@$box -- '$command'"
run "echo 0 | ssh $ssh_options -p $port vagrant@$box -- cat"


