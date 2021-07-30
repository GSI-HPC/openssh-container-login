# SSH Container Login

This example uses [Singularity][03] as container runtime. However this 
approach should be applicable to other container runtimes as well. Users
specify an environment variable `SINGULARITY_CONTAINER` before executing
`ssh` login in order to select a container on the login node. `sshd` 
executes a custom script to then launch the requested container as login
environment.


From the `sshd_config` manual:


> **AcceptEnv**
>
> Specifies what environment variables sent by the client will be copied into
> the session's environ(7). See SendEnv in ssh_config(5) for how to configure
> the client. Note that environment passing is only supported for protocol 2.
> Variables are specified by name, which may contain the wildcard characters
> `*` and `?`. Multiple environment variables may be separated by whitespace or
> spread across multiple AcceptEnv directives. Be warned that some environment
> variables could be used to bypass restricted user environments. For this
> reason, care should be taken in the use of this directive. The default is not
> to accept any environment variables.

Enable direct login into a container with following `sshd` configuration:

```
AcceptEnv SINGULARITY_CONTAINER
ForceCommand /etc/ssh/sshd_container.sh
```

`ForceCommand` executes the script [sshd_container.sh][02] to consume this
environment variable, validates its input and launches a container during `ssh`
login. Administrators customize the behavior of the login script via a
default configuration file [sshd_container][01]:

File                          | Description
------------------------------|-----------------------------------
[sshd_container][01]          | Configuration file (default path `/etc/default/sshd_container`)
[sshd_container.sh][02]       | Login script (default path `/etc/ssh/sshd_container.sh`) 


### Development

Build two simple test singularity containers with [containers.sh](containers.sh).
(This requires `singularity` installed on the host.)

Work on the login script using you localhost:

```bash
SSHD_CONTAINER_DEBUG=true \
SINGULARITY_CONTAINER=menu \
SSHD_CONTAINER_CONFIG=sshd_container \
        ./sshd_container.sh
```

Bootstrap a test virtual machine using the included [Vagrantfile](Vagrantfile).

Start `sshd` on port 23 in foreground for debugging:

```bash
# start a second instance of sshd in foreground on port 23
vagrant ssh -- sudo /sbin/sshd -d -p 23
# connect via the forwarding port...
vagrant ssh-config > ssh-config
ssh -F ssh-config -p 2223 vagrant@ssh-container
```

Uncomment `systemctl restart sshd.service` in the [Vagrantfile][Vagrantfile] to
run on the default port.

### Usage

By **default `ssh` login launches a container specified with `SSHD_CONTAINER_DEFAULT`**:

```
>>> ssh -F ssh-config vagrant@ssh-container   
Container launched: /tmp/debian10.sif
vagrant@centos7:~ >
```

Users can **specify a specific container with the variable `SINGULARITY_CONTAINER`**:

```bash
>>> SINGULARITY_CONTAINER=/tmp/centos7.sif \
        ssh -F ssh-config -o SendEnv=SINGULARITY_CONTAINER vagrant@ssh-container 
Container launched: /tmp/centos7.sif
vagrant@centos7:~ > 
```

From the `ssh_config` manual:

> **SendEnv**
>
> Specifies what variables from the local environ(7) should be sent to the
> server. Note that environment passing is only supported for protocol 2. The
> server must also support it, and the server must be configured to accept
> these environment variables. Refer to `AcceptEnv` in sshd_config(5) for how
> to configure the server. Variables are specified by name, which may contain
> wildcard characters. Multiple environment variables may be separated by
> whitespace or spread across multiple `SendEnv` directives. The default is not
> to send any environment variables.

**Use `none` to prevent any container from launch** and drop the user into a
shell running on the host environment:

```bash
# append to configuration the client SSH configuration
>>> echo "  SendEnv=SINGULARITY_CONTAINER" >> ssh-config
>>> SINGULARITY_CONTAINER=none ssh -F ssh-config vagrant@ssh-container
[vagrant@centos7 ~]$
```

**`menu` will present a list of available containers** defined in the
[sshd_container][01] configuration:

```bash
>>> SINGULARITY_CONTAINER=menu ssh -F ssh-config vagrant@ssh-container
Available containers
1) /tmp/debian10.sif
2) /tmp/centos7.sif
3) none
Select: 2
Container launched: /tmp/centos7.sif
vagrant@centos7:~ >
```


[01]: sshd_container
[02]: sshd_container.sh
[03]: https://sylabs.io/singularity/
