# OpenSSH Container Login

The [`sshd_container.sh`][02] script distributed in this repository is used in
conjunction with the OpenSSH `sshd` daemon to launch a Linux container for each
`ssh` login from a client. This containerizes the environment of user sessions
by default. Users may specify an environment variable `SINGULARITY_CONTAINER`
before executing `ssh` login in order to select a specific container on the
login node.

_Note that this implementation uses [Singularity][03] as container run-time.
However this approach should be applicable to other container run-time systems
as well (for example [Podman][04])._

## Configuration

File                          | Description
------------------------------|-----------------------------------
[sshd_container][01]          | Configuration file (default path `/etc/default/sshd_container`)
[sshd_container.sh][02]       | Login script (default path `/etc/ssh/sshd_container.sh`) 

Copy the configuration file [`sshd_container`][01] and the
[`sshd_container.sh`][02] login script to the expected default locations. Add
following lines to `/etc/ssh/sshd_config`and restart `sshd`:

```bash
AcceptEnv SINGULARITY_CONTAINER
ForceCommand /etc/ssh/sshd_container.sh
```

The line above configures the OpenSSH daemon to accept `SINGULARITY_CONTAINER` as input
environment variable using the configuration option `AcceptEnv` (from the
`sshd_config` manual):

> **AcceptEnv**
>
> Specifies what environment variables sent by the client will be copied into
> the session's environ(7). See `SendEnv` in ssh_config(5) for how to configure
> the client. Note that environment passing is only supported for protocol 2.
> Variables are specified by name, which may contain the wildcard characters
> `*` and `?`. Multiple environment variables may be separated by whitespace or
> spread across multiple `AcceptEnv` directives. Be warned that some environment
> variables could be used to bypass restricted user environments. For this
> reason, care should be taken in the use of this directive. The default is not
> to accept any environment variables.


`ForceCommand` executes the script [`sshd_container.sh`][02] which reads the
`SINGULARITY_CONTAINER` environment variable, validates the input and launches
a container during `ssh` login. 

> **ForceCommand**
> 
> Forces the execution of the command specified by `ForceCommand`, ignoring any
> command supplied by the client and `~/.ssh/rc` if present. The command is
> invoked by using the user's login shell with the `-c` option. This applies to
> shell, command, or subsystem execution. It is most useful inside a Match
> block. The command originally supplied by the client is available in the
> `SSH_ORIGINAL_COMMAND` environment variable. Specifying a command of
> internal-sftp will force the use of an in-process SFTP server that requires
> no support files when used with `ChrootDirectory`. The default is none.

Customize the behavior of the login script via the configuration
file [`sshd_container`][01]:

Variable                    | Description
----------------------------|-------------------------------------
`SSHD_CONTAINER_DEFAULT`    | Default container to start unless the user passes the environment variable `SINGULARITY_CONTAINER` at login.
`SSHD_CONTAINER_OPTIONS`    | Command-line options appended to the `singularity` command at container launch. For example `--bind=/srv`, reference the [Singularity][03] admin manual for more details.
`SSHD_CONTAINER_MENU`       | List of containers presented to the user for selection when requesting a menu with `SINGUALRITY_CONTAINER=menu`.

## Usage

Usage of the `SINGULARITY_CONTAINER` environment variable in the shell
environment on the `ssh` client:

Variable                        | Description
--------------------------------|---------------------------------------
`SINGULARITY_CONTAINER=`        | Unset, empty of blank will launch the default container defined in `SSHD_CONTAINER_DEFAULT`.
`SINGULARITY_CONTAINER=${path}` | Launches a container specified by a user.
`SINGULARITY_CONTAINER=none`    | No container is launched, effective login into the host environment
`SINGULARITY_CONTAINER=menu`    | Present the user a selection menu with a list of container specified in `SSHD_CONTAINER_MENU`


Users need to make sure to **propagate the `SINGULARITY_CONTAINER` environment
variable to the server** using the `SendEnv` configuration option (from the
`ssh_config` manual):

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

Note tat the `root` account will always default to
`SINGULARITY_CONTAINER=none`.  This grantees administrative access to a node.
This is particularly imported if there is only a single `sshd` instance running
on the node. Either use the SSH client option `-o
SendEnv=SINGULARITY_CONTAINER` or append this configuration an SSH per-user
configuration file in `~/.ssh/config` or the  system-wide configuration file
in `/etc/ssh/ssh_config`.

## Development & Testing

Build the required singularity containers with the script [`containers.sh`][05].
(This requires the `singularity` command installed on the host). The containers
generated by the script are stored under `/tmp/*.sif`.

Work on the login script using your host:

```bash
SSHD_CONTAINER_DEBUG=true \
SINGULARITY_CONTAINER=menu \
SSHD_CONTAINER_CONFIG=sshd_container \
        bash -x ./sshd_container.sh
```

Start the test environment using the included [`Vagrantfile`][08]:

* Installs the `singularity` package from Fedora EPEL
* Copies the Singularity containers to `/tmp`
* Deploys [`sshd_container`][01] and [`sshd_container.sh`][02]
* Configures `AcceptEnv` and `ForceCommand` in `/etc/ssh/sshd_config`

```bash
vagrant up centos7-test
```

Start `sshd` on port 23 in foreground for debugging:

```bash
# start a second instance of sshd in foreground on port 23
vagrant ssh centos7-test -- sudo /sbin/sshd -o LogLevel=DEBUG -De -p 23
# connect via the forwarding port (cf. Vagrantfile)
vagrant ssh-config centos7-test > ssh-config
ssh -F ssh-config -p 2223 vagrant@centos7-test
```

`ssh-config` provides the default configuration from Vagrant to connect with
SSH to the box. Either alter the configuration file or use the SSH option `-p`
to connect with the **non default port 2223**. Alternatively restart
`sshd.service` to run on the default port 22:

```bash
vagrant ssh centos7-test -- sudo systemctl restart sshd.service
# Note that this will influence `vagrant ssh` login and may make it difficult to
# debug any issue with SSH login.
```

The [`test.sh`](test.sh) script runs `ssh`, `scp`, `rsync` and `sftp` commands
against the vagrant box for testing various command configurations on multiple
different containers.

The reset of this section illustrates some examples for testing the
functionality of the login script manually.  Adjust the `ssh-config` for the
following example accordingly:

```bash
# propagete SINGULARITY_CONTAINER to the server
echo "  SendEnv=SINGULARITY_CONTAINER" >> ssh-config
# change the SSH forwarding port (cf. Vagrantfile)
sed -i 's/2222/2223/' ssh-config
```

By default login launches a container specified with `SSHD_CONTAINER_DEFAULT`:

```bash
# login into a containerized interactive shell
>>> ssh -F ssh-config vagrant@centos7-test
Container launched: /tmp/debian10.sif
vagrant@centos7:~ >
# run a containerized command
>>> ssh -F ssh-config vagrant@centos7-test -- /bin/ps -fH
UID        PID  PPID  C STIME TTY          TIME CMD
vagrant   2832  2829  0 06:01 ?        00:00:00 sshd: vagrant@notty
vagrant   2833  2832  0 06:01 ?        00:00:00   Singularity runtime parent
vagrant   2854  2833  0 06:01 ?        00:00:00     /bin/ps -fH
# test if stdin works as expected
>>> echo 1 2 3 4 | ssh -F ssh-config vagrant@centos7-test -- cat
1 2 3 4
```

File transfer with `scp`, `rsync` and `sftp`:

```bash
scp -d -F ssh-config vagrant@centos7-test:/bin/bash /tmp
scp -d -F ssh-config /bin/bash vagrant@centos7-test:/tmp
rsync -e 'ssh -F ssh-config' /bin/bash vagrant@centos7-test:/tmp
rsync -e 'ssh -F ssh-config' vagrant@centos7-test:/bin/bash /tmp
sftp -F ssh-config vagrant@centos7-test:/bin/bash /tmp
sftp -F ssh-config vagrant@centos7-test:/tmp <<< $'put /bin/bash'
```

_Note that the container images require to have corresponding packages
installed cf. [`containers.sh`][05]._

Users can specify a specific container with the variable `SINGULARITY_CONTAINER`:

```bash
>>> SINGULARITY_CONTAINER=/tmp/centos7.sif \
        ssh -F ssh-config -o SendEnv=SINGULARITY_CONTAINER vagrant@centos7-test
Container launched: /tmp/centos7.sif
vagrant@centos7:~ > 
```

Login into the host environment using `SINGULARITY_CONTAINER=none`:

```bash
>>> SINGULARITY_CONTAINER=none ssh -F ssh-config vagrant@centos7-test
[vagrant@centos7 ~]$
```

`SINGULARITY_CONTAINER=menu` will present a list of available containers defined
in the [`sshd_container`][01] configuration:

```bash
>>> SINGULARITY_CONTAINER=menu ssh -F ssh-config vagrant@centos7-test
Available containers
1) /tmp/debian10.sif
2) /tmp/centos7.sif
3) none
Select: 2
Container launched: /tmp/centos7.sif
vagrant@centos7:~ >
```

## Packaging

This repository includes an RPM Spec file [`openssh-container-login.spec`][07]
used to build an RPM package as described in the [RPM Packaging Guide][06].

Start the package build in a Vagrant box specified in [`Vagrantfile`][08].

```bash
box=el8 # for example Enterprise Linux 8
# build test containers, start the Vagrant box and login
./containers.sh && vagrant up $box && vagrant ssh $box
```

Build the RPM package:

```bash
# synced with the host
cd /vagrant
# initilize the build environment
rpmdev-setuptree
# copy the login script into the build environment
cp -v /vagrant/{LICENSE,README.md,sshd_container.sh} ~/rpmbuild/BUILD
# build the package
rpmbuild -ba /vagrant/openssh-container-login.spec
# list files in the package
rpm -vql ~/rpmbuild/{SRPMS,RPMS/noarch}/openssh-container-login*.rpm
```

Use the Vagrant [vagrant-rsync-back][09] plug-in to copy the RPM packages
from the box into the development repository:

```bash
# copy the packages into the working-directory
cp ~/rpmbuild/{SRPMS,RPMS/noarch}/openssh-container-login*.rpm /vagrant
# install the plugin if required
vagrant plugin install vagrant-rsync-back
# download packages from the Vagrant box
vagrant rsync-back $box
```

[01]: sshd_container
[02]: sshd_container.sh
[03]: https://sylabs.io/singularity
[04]: https://podman.io
[05]: containers.sh
[06]: https://rpm-packaging-guide.github.io
[07]: openssh-container-login.spec
[08]: Vagrantfile
[09]: https://github.com/smerrill/vagrant-rsync-back
