# -*- mode: ruby -*-
# vi: set ft=ruby :

sshd_config = %q(
PermitRootLogin yes
AcceptEnv SINGULARITY_CONTAINER
ForceCommand /etc/ssh/sshd_container.sh
)

Vagrant.configure('2') do |config|
  config.vm.define "ssh-container" do |config|

    config.vm.hostname = "centos7"
    config.vm.box = "centos/7"
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # use this for a second sshd instance...
    config.vm.network "forwarded_port", host: 2223, guest: 23

    # copy files into the box
    config.vm.box_check_update = false
    %w(
      sshd_container
      sshd_container.sh
      /tmp/debian10.sif
      /tmp/centos7.sif
     ).each do |file|
       name = File.basename file
       config.vm.provision "file", source: "#{file}", destination: "/tmp/#{name}"
    end

    # install dependencies and configured sshd
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
        mkdir ~root/.ssh
        chmod 700 ~root/.ssh
        cat ~vagrant/.ssh/authorized_keys >> ~root/.ssh/authorized_keys
        chmod 600 ~root/.ssh/authorized_keys
      )
    end
  end
end
