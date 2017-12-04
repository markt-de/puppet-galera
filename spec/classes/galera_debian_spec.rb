require 'spec_helper'

describe 'galera::debian' do
  let :pre_condition do
    "class { 'galera':
       galera_master => 'control1',
       status_password => 'nonempty'
    }"
  end

  shared_examples_for 'galera on Debian' do
    context 'with default parameters' do
      it { should contain_exec('clean_up_ubuntu').with(
        :command     => "service mysql stop",
        :path        => "/usr/bin:/bin:/usr/sbin:/sbin",
        :refreshonly => true,
        :subscribe   => "Package[mysql-server]"
      ) }
    end

    context 'when this node is the master' do
      before(:each) do
        facts.merge!({
          :fqdn => 'control1',
        })
      end
      let(:node) { 'control1' }

      it { should contain_mysql_user('debian-sys-maint@localhost').with(
        :ensure   => 'present',
        :provider => 'mysql',
        :require  => "File[#{facts[:root_home]}/.my.cnf]"
      ) }

      it { should contain_mysql_grant('debian-sys-maint@localhost/*.*').with(
        :ensure     => 'present',
        :options    => ['GRANT'],
        :privileges => ['ALL'],
        :table      => '*.*',
        :user       => 'debian-sys-maint@localhost',
      ) }

      it { should contain_file('/etc/mysql/debian.cnf').with(
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0600',
        :require => 'Mysql_user[debian-sys-maint@localhost]'
      ) }

      it { should_not contain_file('/etc/mysql/debian.cnf').with(
        :before => 'Service[mysql]'
      ) }
    end

    context 'when this node is a slave' do
      before(:each) do
        facts.merge!({
          :fqdn => 'slave',
        })
      end
      let(:node) { 'slave' }

      it { should_not contain_mysql_user('debian-sys-maint@localhost').with(
        :ensure   => 'present',
        :provider => 'mysql',
        :require  => "File[/#{facts[:root_home]}/.my.cnf]"
      ) }

      it { should_not contain_file('/etc/mysql/debian.cnf').with(
        :require => 'Mysql_user[debian-sys-maint@localhost]'
      ) }
    end
  end

  on_supported_os.each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge({})
      end

      case facts[:osfamily]
      when 'Debian'
        it_configures 'galera on Debian'
      end
    end
  end


end
