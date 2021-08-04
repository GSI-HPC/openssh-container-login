# OpenSSH Container Login

This example uses [Singularity][03] as container runtime. However this approach
should be applicable to other container runtimes as well. **Users may specify
an environment variable `SINGULARITY_CONTAINER` before executing `ssh` login in
order to select a container on the login node.** `sshd` executes a custom
script to then launch the requested container as login environment.

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

## Development

Build two singularity containers with the script [containers.sh](containers.sh).
(This requires `singularity` installed on the host). Containers are stored in
`/tmp/{debian10,centos7}.sif` for testing login into a container.

Work on the login script using you localhost:

```bash
SSHD_CONTAINER_DEBUG=true \
SINGULARITY_CONTAINER=menu \
SSHD_CONTAINER_CONFIG=sshd_container \
        bash ./sshd_container.sh
```

Bootstrap a test virtual machine using the included [Vagrantfile](Vagrantfile):

* Installs the `singularity` package from Fedora EPEL
* Copies the Singularity containers to `/tmp`
* Deploys [sshd_container][01] and [sshd_container.sh][02]
* Configures `AcceptEnv` and `ForceCommand` in `/etc/ssh/sshd_config`

Start `sshd` on port 23 in foreground for debugging:

```bash
# start a second instance of sshd in foreground on port 23
vagrant ssh -- sudo /sbin/sshd -d -p 23
# connect via the forwarding port...
vagrant ssh-config > ssh-config
ssh -F ssh-config -p 2223 vagrant@ssh-container
```

Alternatively restart `sshd.service` to run on the default port 22:

```bash
vagrant ssh -- sudo systemctl restart sshd.service
```

## Configuration

Variables in the [sshd_container][01] configuration file:

Name                        | Description
----------------------------|-------------------------------------
`SSHD_CONTAINER_DEFAULT`    | Default container to start unless the users passes the environment variable `SINGULARITY_CONTAINER` at login.
`SSHD_CONTAINER_OPTIONS`    | Command-line options appended to the `singularity` command at container luanch, i.e. `--bind=/srv`.
`SSHD_CONTAINER_MENU`       | Items presented to the user for selection when requesting a menu with `SINGUALRITY_CONTAINER=menu`.


## Usage

Variable                        | Description
--------------------------------|---------------------------------------
`SINGULARITY_CONTAINER=`        | Unset, empty of blank will launch the default container defined in `SSHD_CONTAINER_DEFAULT`.
`SINGULARITY_CONTAINER=${path}` | Launches a container specified by a user.
`SINGULARITY_CONTAINER=none`    | No container is launched, effective login into the host environment
`SINGULARITY_CONTAINER=menu`    | Present the user a selection menu with a list of container specified in `SSHD_CONTAINER_MENU`

_Note that `ssh-config` provides the default configuration from
Vagrant to connect with SSH to the box. This file is generated
in the Development section above._


By **default `ssh` login launches a container specified with
`SSHD_CONTAINER_DEFAULT`**:

```
# login into a containerized interactive shell
>>> ssh -F ssh-config vagrant@ssh-container   
Container launched: /tmp/debian10.sif
vagrant@centos7:~ >
# run a containerized command
>>> ssh -F ssh-config vagrant@ssh-container -- /bin/ps -fH
UID        PID  PPID  C STIME TTY          TIME CMD
vagrant   2832  2829  0 06:01 ?        00:00:00 sshd: vagrant@notty
vagrant   2833  2832  0 06:01 ?        00:00:00   Singularity runtime parent
vagrant   2854  2833  0 06:01 ?        00:00:00     /bin/ps -fH
```

File transfer with `scp` and `rsync`:

```bash
scp -d -F ssh-config vagrant@ssh-container:/bin/bash /tmp
scp -d -F ssh-config /bin/bash vagrant@ssh-container:/tmp
rsync -e 'ssh -F ssh-config' /bin/bash vagrant@ssh-container:/tmp
rsync -e 'ssh -F ssh-config' vagrant@ssh-container:/bin/bash /tmp
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
