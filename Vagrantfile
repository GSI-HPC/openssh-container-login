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

    # use this for a second sshd instance...
    config.vm.network "forwarded_port", host: 2223, guest: 23

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


    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %Q(
        yum install -y vim epel-release
        yum install -y singularity
        cp -v /tmp/*.sif /srv/
        cp -v /tmp/sshd_container /etc/default/
        cp -v /tmp/sshd_container.sh /etc/ssh/
        grep -q ^ForceCommand /etc/ssh/sshd_config || echo "#{sshd_config}" | tee -a /etc/ssh/sshd_config
        mkdir -p /etc/slurm /var/run/munge /var/spool/slurm /var/lib/sss/pipes/nss /cvmfs
    #    systemctl restart sshd.service
      )
    end
  end
end
