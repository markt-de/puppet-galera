require 'spec_helper'

describe 'galera' do
  let(:params) do
    {
      bind_address: '10.2.2.1',
      cluster_name: 'testcluster',
      configure_firewall: true,
      configure_repo: true,
      deb_sysmaint_password: 'sysmaint',
      galera_master: 'control1',
      galera_servers: ['10.2.2.1'],
      local_ip: '10.2.2.1',
      mysql_port: 3306,
      mysql_restart: false,
      override_options: {},
      package_ensure: 'present',
      root_password: 'test',
      status_password: 'nonempty',
      vendor_type: 'percona',
      vendor_version: '8.0',
      wsrep_group_comm_port: 4567,
      wsrep_inc_state_transfer_port: 4568,
      wsrep_sst_method: 'rsync',
      wsrep_state_transfer_port: 4444,
    }
  end

  shared_examples_for 'galera on Debian' do
    context 'with default parameters' do
      it {
        is_expected.to contain_systemd__manage_unit('mysqlchk.socket').with(
          socket_entry: {
            'ListenStream' => 9200,
            'Accept' => true,
          },
        )
      }
      it { is_expected.to create_systemd__daemon_reload('mysqlchk.socket') }
      it {
        is_expected.to contain_systemd__manage_unit('mysqlchk@.service').with(
          service_entry: {
            'User' => 'clustercheck',
            'Group' => 'clustercheck',
            'StandardInput' => 'socket',
            'ExecStart' => '/usr/local/bin/clustercheck',
          },
        )
      }
      it { is_expected.to create_systemd__daemon_reload('mysqlchk@.service') }
    end

    context 'when this node is the master' do
      before(:each) do
        facts.deep_merge!(networking: { 'fqdn' => 'control1' })
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
        facts.deep_merge!(networking: { 'fqdn' => 'slave' })
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

  shared_examples_for 'galera on Debian 11 and older' do
    context 'when installing percona' do
      it {
        is_expected.to contain_xinetd__service('mysqlchk').with(
          log_on_success: '',
          log_on_success_operator: '=',
          log_on_failure: nil,
        )
      }
    end
    context 'when specifying logging options' do
      before(:each) do
        params.merge!(status_log_on_success: 'PID HOST USERID EXIT DURATION TRAFFIC',
                      status_log_on_success_operator: '-=',
                      status_log_on_failure: 'USERID')
      end
      it {
        is_expected.to contain_xinetd__service('mysqlchk').with(
          log_on_success: 'PID HOST USERID EXIT DURATION TRAFFIC',
          log_on_success_operator: '-=',
          log_on_failure: 'USERID',
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts
      end

      case facts[:os]['family']
      when 'Debian'
        if facts[:os]['name'] == 'Debian' && Puppet::Util::Package.versioncmp(facts[:os]['release']['major'], '12') >= 0
          it_configures 'galera on Debian'
        elsif facts[:os]['name'] == 'Ubuntu' && Puppet::Util::Package.versioncmp(facts[:os]['release']['full'], '24.04') >= 0
          it_configures 'galera on Debian'
        else
          it_configures 'galera on Debian 11 and older'
        end
      end
    end
  end
end
