# -*- mode: ruby -*-
# vi: set ft=ruby :

debian_def = %q(
Bootstrap: docker
From: debian:10
)

centos_def = %q(
Bootstrap: docker
From: centos:7
)

sshd_config = %q(
AcceptEnv VAE
ForceCommand /etc/ssh/sshd_container.sh
)

Vagrant.configure('2') do |config|
  config.vm.define "ssh-container" do |config|

    config.vm.hostname = "centos7"
    config.vm.box = "centos/7"

    config.vm.box_check_update = false
    %w(
      sshd_container
      sshd_container.sh
     ).each do |file|
      config.vm.provision "file", source: "#{file}", destination: "/tmp/#{file}"
    end

    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %Q(
        yum install -y vim epel-release
        yum install -y singularity
        echo "#{debian_def}" > /tmp/debian.def
        test -f /srv/debian.sif || singularity build /srv/debian.sif /tmp/debian.def
        echo "#{centos_def}" > /tmp/centos.def
        test -f /srv/centos.sif || singularity build /srv/centos.sif /tmp/centos.def
        cp -v /tmp/sshd_container /etc/default/
        cp -v /tmp/sshd_container.sh /etc/ssh/
        grep -q ^ForceCommand /etc/ssh/sshd_config || echo "#{sshd_config}" | tee -a /etc/ssh/sshd_config
      )
    end
  end
end
