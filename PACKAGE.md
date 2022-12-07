
# Packages

This repository includes 

* ...an RPM Spec file [`openssh-container-login.spec`](openssh-container-login.spec)
* ...used to build an RPM package as described in the [RPM Packaging Guide][01]

[01]: https://rpm-packaging-guide.github.io

```sh
# install and setup the RPM and build tools...
sudo dnf install -y @rpm-development-tools
# initilize the build environment
rpmdev-setuptree

# build the RPM package...
cp -vr ./* ~/rpmbuild/BUILD && rpmbuild -ba openssh-container-login.spec

# list files in the package
rpm -vql ~/rpmbuild/{SRPMS,RPMS/noarch}/openssh-container-login*.rpm
```

