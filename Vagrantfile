# -*- mode: ruby -*-
# vi: set ft=ruby :

# Change this to swap between a centos and an ubuntu box
box = 'puppetlabs/centos-7.0-64-puppet'
#box = 'trusty64'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "control1" do |control1|
    control1.vm.box = box
    control1.vm.network "private_network", ip: "192.168.99.101"
    control1.vm.provider "virtualbox" do |v|
      v.customize ['modifyvm', :id ,'--memory','1024']
    end
    control1.vm.hostname = 'control1'

    control1.vm.provision :shell do |shell|
      shell.inline = 'cp -r /vagrant/modules/* /etc/puppet/modules; ' +
               'ln -s /vagrant /etc/puppet/modules/galera'
    end

    if box == 'precise64' or box == 'trusty64'
      control1.vm.provision :shell do |shell|
        script =
        "if grep 127.0.1.1 /etc/hosts ; then \n" +
        " sed -i -e \"s/127.0.1.1.*/127.0.1.1 control1.domain.name control1/\" /etc/hosts\n" +
        "else\n" +
        "  echo '127.0.1.1 control1.domain.name control1' >> /etc/hosts\n" +
        "fi ;"
        shell.inline = script
      end
    elsif  (box == 'centos64' or box == 'puppetlabs/centos-7.0-64-puppet')
      control1.vm.provision :shell do |shell|
        shell.inline = "echo '192.168.99.101 control1.domain.name control1' > /etc/hosts;" +
                       "echo '127.0.0.1 control1 localhost localhost.localdomain localhost4 localhost4.localdomain4' >> /etc/hosts;" +
                       "echo '::1 localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts;"
      end
    end

    if ENV['http_mirror']
        if box == 'precise64'
          control1.vm.provision :shell do |shell|
            shell.inline = "sed -i 's/us.archive.ubuntu.com/%s/g' /etc/apt/sources.list" % ENV['http_mirror']
          end
        end
    end

    if ENV['http_proxy']
        if box == 'precise64'
          control1.vm.provision :shell do |shell|
            shell.inline = 'echo "Acquire::http { Proxy \"http://%s\"; };" > /etc/apt/apt.conf.d/01apt-cacher-ng-proxy;' % ENV['http_proxy']
          end
      end
    end

    if  (box == 'centos64' or box == 'puppetlabs/centos-7.0-64-puppet')
      control1.vm.provision :shell do |shell|
        shell.inline = 'puppet apply /vagrant/examples/centos7.pp'
      end
    else
      control1.vm.provision :shell do |shell|
        shell.inline = 'puppet apply /vagrant/examples/site.pp'
      end
    end

  end

  config.vm.define "control2" do |control2|
    control2.vm.box = box
    control2.vm.network "private_network", ip: "192.168.99.102"
    control2.vm.provider "virtualbox" do |v|
      v.customize ['modifyvm', :id ,'--memory','1024']
    end

    control2.vm.hostname = 'control2'

    control2.vm.provision :shell do |shell|
      shell.inline = 'cp -r /vagrant/modules/* /etc/puppet/modules; ' +
               'ln -s /vagrant /etc/puppet/modules/galera'
    end

    if box == 'precise64' or box == 'trusty64'
      control2.vm.provision :shell do |shell|
        script =
        "if grep 127.0.1.1 /etc/hosts ; then \n" +
        " sed -i -e \"s/127.0.1.1.*/127.0.1.1 control2.domain.name control2/\" /etc/hosts\n" +
        "else\n" +
        "  echo '127.0.1.1 control2.domain.name control2' >> /etc/hosts\n" +
        "fi ;"
        shell.inline = script
      end
    end

    if (box == 'centos64' or box == 'puppetlabs/centos-7.0-64-puppet')
      control2.vm.provision :shell do |shell|
        shell.inline = "echo '192.168.99.102 control2.domain.name control2' > /etc/hosts;" +
                       "echo '127.0.0.1 control2 localhost localhost.localdomain localhost4 localhost4.localdomain4' >> /etc/hosts;" +
                       "echo '::1 localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts;"
      end
    end

    if ENV['http_mirror']
        if box == 'precise64'
          control1.vm.provision :shell do |shell|
            shell.inline = "sed -i 's/us.archive.ubuntu.com/%s/g' /etc/apt/sources.list" % ENV['http_mirror']
          end
        end
    end

    if ENV['http_proxy']
        if box == 'precise64'
          control1.vm.provision :shell do |shell|
            shell.inline = 'echo "Acquire::http { Proxy \"http://%s\"; };" > /etc/apt/apt.conf.d/01apt-cacher-ng-proxy;' % ENV['http_proxy']
          end
      end
    end

    if  (box == 'centos64' or box == 'puppetlabs/centos-7.0-64-puppet')
      control2.vm.provision :shell do |shell|
        shell.inline = 'puppet apply /vagrant/examples/centos7.pp'
      end
    else
      control2.vm.provision :shell do |shell|
        shell.inline = 'puppet apply /vagrant/examples/site.pp'
      end
    end

  end
end
