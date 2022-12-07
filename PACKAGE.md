
# Packages

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

Configure `sshd` for testing:

```bash
# install the packages
sudo rpm -i rpmbuild/{SRPMS,RPMS/noarch}/openssh-container-login*.rpm
# append configuration for the sshd daemon
cat <<EOF | sudo tee -a /etc/ssh/sshd_config
PermitRootLogin yes
AcceptEnv APPTAINER_CONTAINER SSHD_CONTAINER_*
ForceCommand /etc/ssh/sshd_container.sh
EOF
# add the Vagrant SSH key to the root account
sudo -- sh -c '
        mkdir ~root/.ssh && chmod 700 ~root/.ssh
        cat ~vagrant/.ssh/authorized_keys > ~root/.ssh/authorized_keys
        chmod 600 ~root/.ssh/authorized_keys
'
# restart the sshd daemon
sudo systemctl restart sshd
```

Cf. development & testing section above.

Copy the RPM packages from the box into the development repository:

```bash
vagrant ssh-config $box > ssh-config
# copy the packages into the working-directory
scp -F ssh-config vagrant@${box}:'rpmbuild/{SRPMS,RPMS/noarch}/openssh-container-login*.rpm' .
```


[06]: https://rpm-packaging-guide.github.io
[07]: openssh-container-login.spec
[08]: Vagrantfile
