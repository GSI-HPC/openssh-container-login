# -*- mode: ruby -*-
# vi: set ft=ruby :

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
      debian10.sif
      centos7.sif
     ).each do |file|
      config.vm.provision "file", source: "#{file}", destination: "/tmp/#{file}"
    end


    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %Q(
        yum install -y vim epel-release
        yum install -y singularity
        cp -v /tmp/*.sif /srv/
        cp -v /tmp/sshd_container /etc/default/
        cp -v /tmp/sshd_container.sh /etc/ssh/
        grep -q ^ForceCommand /etc/ssh/sshd_config || echo "#{sshd_config}" | tee -a /etc/ssh/sshd_config
        systemctl restart sshd.service
      )
    end
  end
end
