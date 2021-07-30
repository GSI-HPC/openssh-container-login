# SSH Container Login

Enable direct login into a container with following `sshd` configuration:

```
AcceptEnv SINGULARITY_CONTAINER
ForceCommand /etc/ssh/sshd_container.sh
```

This uses an Environment variable `SINGULARITY_CONTAINER` to select a target
container images for logins.

File                          | Description
------------------------------|-----------------------------------
[sshd_container][01]          | Configuration files (default path `/etc/default/sshd_container`)
[sshd_container.sh][02]       | Login script (default path `/etc/ssh/sshd_container.sh`) 

[01]: sshd_container
[02]: sshd_container.sh

Build two simple test singularity containers with [containers.sh](containers.sh).

```bash
# test the script on localhost
SSHD_CONTAINER_DEBUG=true SINGULARITY_CONTAINER=menu SSHD_CONTAINER_CONFIG=sshd_container ./sshd_container.sh
```

```bash
# start a second instance of sshd in foreground on port 23
vagrant ssh -- sudo /sbin/sshd -d -p 23
# connect via the forwarding port...
vagrant ssh-config > ssh-config
ssh -F ssh-config -p 2223 vagrant@ssh-container
```
