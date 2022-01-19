# -*- mode: ruby -*-
# vi: set ft=ruby :

##
# Configuration file for the `sshd` daemon
#
sshd_config = %q(
PermitRootLogin yes
AcceptEnv SINGULARITY_CONTAINER SSHD_CONTAINER_*
ForceCommand /etc/ssh/sshd_container.sh
)

Vagrant.configure('2') do |config|

  ##
  # CentOS 7 environment for development and testing
  #
  config.vm.define "centos7-test" do |config|

    config.vm.hostname = "centos7-test"
    config.vm.box = "centos/7"

    # Disable sync of the development repository into the box
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # Use this for a second `sshd` instance...
    config.vm.network "forwarded_port", host: 2223, guest: 23

    # Copy files into the box
    #
    # - configuration file and login script
    # - singularity container images
    config.vm.box_check_update = false
    %w(
      sshd_container
      sshd_container.sh
      /tmp/debian10.sif
      /tmp/centos7.sif
      /tmp/centos_stream8.sif
     ).each do |file|
       name = File.basename file
       config.vm.provision "file", source: "#{file}", destination: "/tmp/#{name}"
    end

    # Setup the development environment
    #
    # - install singularity
    # - move the configuration file and login script to the default paths
    # - configure `sshd` daemon
    # - add the vagrant ssh key to the root account
    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %Q(
        yum install -y vim epel-release
        yum install -y singularity
        echo 'Text from /etc/motd' > /etc/motd
        echo 'Dummy content' > /srv/dummy.txt 
        cp -v /tmp/sshd_container /etc/default/sshd_container
        cp -v /tmp/sshd_container.sh /etc/ssh/sshd_container.sh
        grep -q ^ForceCommand /etc/ssh/sshd_config || echo "#{sshd_config}" | tee -a /etc/ssh/sshd_config
        test -d ~root/.ssh || mkdir ~root/.ssh
        chmod 700 ~root/.ssh
        cat ~vagrant/.ssh/authorized_keys > ~root/.ssh/authorized_keys
        chmod 600 ~root/.ssh/authorized_keys
      )
    end
  end

  ##
  # CentOS 7 environment to build and RPM package from the includes RPM Spec file
  #
  config.vm.define "centos7-package" do |config|

    config.vm.hostname = "centos7-package"
    config.vm.box = "centos/7"

    # Sync the development repository into the box
    config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"
    
    # Use this for a second sshd instance...
    config.vm.network "forwarded_port", host: 2223, guest: 23

    # Build the RPM package
    #
    # - install the RPM development tools
    # - copy the login script into the build environment
    # - build the package
    # - copy the RPM packages from the build environment
    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %q(
        yum install -y vim rpm-build rpmdevtools
        rpmdev-setuptree
        cp -v /vagrant/sshd_container.sh ~/rpmbuild/BUILD
        rpmbuild -ba /vagrant/openssh-container-login.spec
        cp -v $(find ~/rpmbuild/* -name *.rpm) /vagrant
      )
    end

    # Install the package, and configure sshd
    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %Q(
        rpm -v -i $(find ~/rpmbuild/* -name *.rpm)
        grep -q ^ForceCommand /etc/ssh/sshd_config || echo "#{sshd_config}" | tee -a /etc/ssh/sshd_config
      )
    end

  end

  config.vm.define "el8-package" do |config|

    config.vm.hostname = "el8"
    config.vm.box = "rockylinux/8"

    # Sync the development repository into the box
    config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"

    # Use this for a second sshd instance...
    config.vm.network "forwarded_port", host: 2223, guest: 23

    # install package build dependencies
    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %q(dnf install -y vim rpm-build rpmdevtools)
    end

  end

end
