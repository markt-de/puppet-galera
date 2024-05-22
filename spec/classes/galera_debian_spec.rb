require 'spec_helper'

describe 'galera::debian' do
  let :pre_condition do
    "class { 'galera':
       cluster_name    => 'testcluster',
       galera_master   => 'control1',
       package_ensure  => 'present',
       status_password => 'nonempty'
    }"
  end

  shared_examples_for 'galera on Debian' do
    context 'with default parameters' do
      it {
        is_expected.to contain_systemd__manage_unit('mysqlchk.socket').with(
          socket_entry: {
            'ListenStream' => 9200,
            'Accept' => true
          }
        )
      }
      it { is_expected.to create_systemd__daemon_reload('mysqlchk.socket') }
      it {
        is_expected.to contain_systemd__manage_unit('mysqlchk@.service').with(
          service_entry: {
            'User' => 'clustercheck',
            'Group' => 'clustercheck',
            'StandardInput' => 'socket',
            'ExecStart' => '/usr/local/bin/clustercheck'
          }
        )
      }
      it { is_expected.to create_systemd__daemon_reload('mysqlchk@.service') }
      it { is_expected.to contain_file('/etc/mysql/puppet_debfix.cnf').with_content(%r{[mysqld]}) }
      it {
        is_expected.to contain_exec('clean_up_ubuntu').with(
          command: 'service mysql stop',
          path: '/usr/bin:/bin:/usr/sbin:/sbin',
          refreshonly: true,
          subscribe: 'Package[mysql-server]',
        )
      }
      it { is_expected.to contain_file('/var/lib/mysql-install-tmp') }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_I').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_II').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_III').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_IV').with(refreshonly: true) }
    end

    context 'when this node is the master' do
      before(:each) do
        facts.merge!(networking: { 'fqdn' => 'control1' })
      end
      let(:node) { 'control1' }

      it {
        is_expected.to contain_mysql_user('debian-sys-maint@localhost').with(
          ensure: 'present',
          provider: 'mysql',
        )
      }

      it {
        is_expected.to contain_mysql_grant('debian-sys-maint@localhost/*.*').with(
          ensure: 'present',
          options: ['GRANT'],
          privileges: ['ALL'],
          table: '*.*',
          user: 'debian-sys-maint@localhost',
        )
      }

      it {
        is_expected.to contain_file('/etc/mysql/debian.cnf').with(
          owner: 'root',
          group: 'root',
          mode: '0600',
          require: 'Mysql_user[debian-sys-maint@localhost]',
        )
      }

      it {
        is_expected.not_to contain_file('/etc/mysql/debian.cnf').with(
          before: 'Service[mysql]',
        )
      }
    end

    context 'when this node is a slave' do
      before(:each) do
        facts.merge!(networking: { 'fqdn' => 'slave' })
      end
      let(:node) { 'slave' }

      it {
        is_expected.not_to contain_mysql_user('debian-sys-maint@localhost').with(
          ensure: 'present',
          provider: 'mysql',
        )
      }

      it {
        is_expected.not_to contain_file('/etc/mysql/debian.cnf').with(
          require: 'Mysql_user[debian-sys-maint@localhost]',
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts.merge({})
      end

      case facts[:osfamily]
      when 'Debian'
        it_configures 'galera on Debian'
      end
    end
  end
end
