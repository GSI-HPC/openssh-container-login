#!/usr/bin/env bash

# stop on a command failing
set -e

run() {
        echo SSHD_CONTAINER_DEBUG=$SSHD_CONTAINER_DEBUG
        echo SINGULARITY_CONTAINER=$SINGULARITY_CONTAINER
        echo $@
        echo ---------
        eval "$@"
        echo
}

# enable debugging of the login script
export SSHD_CONTAINER_DEBUG=true

# name of the Vagrant box used for testing
box=centos7-test

# command used to identify the user login environment
command='grep -i pretty /etc/os-release ; ps -p $(echo $PPID) -f --no-headers'

# variable for SSH options to the commands
ssh_options='-F ssh-config'

# create a new SSH configuration file
vagrant ssh-config $box > ssh-config

# change to 2222 if sshd runs on the default port
port=2223

# change the SSH forwarding port in the SSH configuration
sed -i "s/2222/$port/" ssh-config

##
# login without environment variable
#

run "ssh $ssh_options root@$box -- '$command'"

##
# login with environment variable
#

# Propagate environment variables to the server
grep 'SendEnv=' ssh-config ||
        echo "  SendEnv=SINGULARITY_CONTAINER SSHD_CONTAINER_DEBUG" >> ssh-config

# root login does not launch a container
run "ssh $ssh_options root@$box -- '$command'"

# non existing container
export SINGULARITY_CONTAINER='foo'
run "ssh $ssh_options vagrant@$box -- '$command'"

##
# empty variable
#

export SINGULARITY_CONTAINER='' # blank environment variable
run "ssh $ssh_options vagrant@$box -- '$command'"
export SINGULARITY_CONTAINER=   # empty environment variable
run "ssh $ssh_options vagrant@$box -- '$command'"
unset SINGULARITY_CONTAINER     # no environment variable
run "ssh $ssh_options vagrant@$box -- '$command'"


##
# default container
#

run "echo 0 | ssh $ssh_options vagrant@$box -- cat"
run "scp -d $ssh_options vagrant@$box:/bin/bash /tmp"
run "scp -d $ssh_options /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options' /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options' vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options vagrant@$box:/tmp <<< $'put /bin/bash'"

##
# specific container
#

export SINGULARITY_CONTAINER=/tmp/centos7.sif
run "ssh $ssh_options vagrant@$box -- '$command'"
run "echo 0 | ssh $ssh_options vagrant@$box -- cat"
run "scp -d $ssh_options vagrant@$box:/bin/bash /tmp"
run "scp -d $ssh_options /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options' /bin/bash vagrant@$box:/tmp"
run "rsync -v -e 'ssh $ssh_options' vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options vagrant@$box:/bin/bash /tmp"
run "sftp $ssh_options vagrant@$box:/tmp <<< $'put /bin/bash'"

##
# no container
#

export SINGULARITY_CONTAINER=none
run "ssh $ssh_options vagrant@$box -- '$command'"
run "echo 0 | ssh $ssh_options vagrant@$box -- cat"


