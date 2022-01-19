Name:           openssh-container-login
Version:        1.0
Release:        0

BuildArch:      noarch
Requires:       openssh-server

URL:            https://github.com/vpenso/openssh-container-login
License:        GPLv3
Summary:        Containerize OpenSSH Client Logins
%description
The sshd_container.sh script distributed in this package is used in
conjunction with the OpenSSH sshd daemon to launch a Linux container for each
ssh login from a client. This containerizes the environment of user sessions by
default. Users may specify an environment variable SINGULARITY_CONTAINER before
executing ssh login in order to select a specific container on the login node.

%install
rm -rf %{buildroot}
# create a minimal configuration file
mkdir -p %{buildroot}/etc/default
cat > %{buildroot}/etc/default/sshd_container <<EOF
export SSHD_CONTAINER_OPTIONS=""
export SSHD_CONTAINER_DEFAULT=""
declare -a SSHD_CONTAINER_MENU=(none)
EOF
# add the login script to the package
mkdir -p %{buildroot}/etc/ssh
cp sshd_container.sh %{buildroot}/etc/ssh/sshd_container.sh

%files
/etc/default/sshd_container
/etc/ssh/sshd_container.sh
%license LICENSE
%doc README.md

%changelog
* Wed Jan 19 2022 Victor Penso <vic.penso@gmail.com> 1.0
  - Add LICENSE and README to the package
  - Build package on Enterprise Linux 8
* Fri Aug 6 2021 Victor Penso <vic.penso@gmail.com> 1.0
  - First version to be packaged
