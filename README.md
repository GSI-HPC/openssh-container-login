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
