Name:           openssh-container-login
Version:        0.1
Release:        0
Summary:        Containerize OpenSSH Client Logins
License:        GPLv3
BuildArch:      noarch

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

mkdir -p %{buildroot}/etc/ssh
cp sshd_container.sh %{buildroot}/etc/ssh/sshd_container.sh


%files
/etc/default/sshd_container
/etc/ssh/sshd_container.sh

%changelog
# todo
