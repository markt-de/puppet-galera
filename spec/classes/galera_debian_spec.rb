require 'spec_helper'

describe 'galera::debian' do

  let :pre_condition do
    "class { 'galera':
       galera_master => 'control1',
       status_password => 'nonempty'
    }"
  end

  context 'with default parameters' do
    let :facts do
      {
        :osfamily => 'Debian'
      }
    end
    it { should contain_exec('clean_up_ubuntu').with(
      :command     => "service mysql stop",
      :path        => "/usr/bin:/bin:/usr/sbin:/sbin",
      :refreshonly => true,
      :subscribe   => "Package[mysql-server]"
    ) }
  end

  context 'when this node is the master' do
    let :facts do
      {
        :fqdn => 'control1',
        :osfamily => 'Debian'
      }
    end
    let(:node) { 'control1' }

    it { should contain_mysql_user('debian-sys-maint@localhost').with(
      :ensure   => 'present',
      :provider => 'mysql',
      :require  => "File[/root/.my.cnf]"
    ) }

    it { should contain_file('/etc/mysql/debian.cnf').with(
      :require => 'Mysql_user[debian-sys-maint@localhost]'
    ) }

    it { should_not contain_file('/etc/mysql/debian.cnf').with(
      :before => 'Service[mysql]'
    ) }
  end

  context 'when this node is a slave' do
    let :facts do
      {
        :fqdn => 'slave',
        :osfamily => 'Debian'
      }
    end
    let(:node) { 'slave' }

    it { should_not contain_mysql_user('debian-sys-maint@localhost').with(
      :ensure   => 'present',
      :provider => 'mysql',
      :require  => "File[/root/.my.cnf]"
    ) }

    it { should_not contain_file('/etc/mysql/debian.cnf').with(
      :require => 'Mysql_user[debian-sys-maint@localhost]'
    ) }
  end
end
