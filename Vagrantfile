# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 1024
    libvirt.cpus = 4
  end

  %w(
    /tmp/debian10.sif
    /tmp/rockylinux8.sif
    /tmp/almalinux9.sif
   ).each do |file|
     name = File.basename file
     config.vm.provision "file", source: "#{file}", destination: "/tmp/#{name}"
  end

  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"
  config.vm.network "forwarded_port", host: 2223, guest: 23

  config.vm.define "el8" do |config|

    config.vm.hostname = "el8"
    config.vm.box = "rockylinux/8"

    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %q(
        dnf install -y epel-release 
        dnf install -y apptainer vim rpm-build rpmdevtools
      )
    end

  end
  
  config.vm.define "el9" do |config|

    config.vm.hostname = "el9"
    config.vm.box = "almalinux/9"

    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = %q(
        dnf install -y epel-release 
        dnf install -y apptainer vim rpm-build rpmdevtools
      )
    end

  end

end
