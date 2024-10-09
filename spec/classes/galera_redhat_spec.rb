require 'spec_helper'

describe 'galera' do
  let(:params) do
    {
      arbitrator_config_file: '/etc/default/garb',
      arbitrator_package_ensure: 'present',
      arbitrator_package_name: 'galera-arbitrator',
      arbitrator_service_name: 'garb',
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

  shared_examples_for 'galera on RedHat' do
    context 'when installing percona' do
      it { is_expected.to contain_class('galera::redhat') }
      it { is_expected.to contain_package(os_params[:p_additional_packages]).with(ensure: 'installed') }
      it { is_expected.to contain_service('mysql@bootstrap') }
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
            'ExecStart' => '-/usr/local/bin/clustercheck',
          },
        )
      }
      it { is_expected.to create_systemd__daemon_reload('mysqlchk@.service') }
    end

    context 'when node is the master' do
      before(:each) { params.deep_merge!(galera_master: facts[:networking]['fqdn']) }
      it { is_expected.to contain_exec('bootstrap_galera_cluster').with_command(%r{--wsrep-new-cluster}) }
    end

    context 'when status_port=12345' do
      before(:each) do
        params.merge!(status_port: 12_345)
      end
      it {
        is_expected.to contain_systemd__manage_unit('mysqlchk.socket').with(
          socket_entry: {
            'ListenStream' => 12_345,
            'Accept' => true,
          },
        )
      }
    end

    context 'when installing mariadb' do
      before(:each) { params.deep_merge!(vendor_type: 'mariadb', vendor_version: '10.11') }

      it { is_expected.to contain_file('/var/log/mariadb') }
      it { is_expected.to contain_file('/var/run/mariadb') }
    end
  end

  shared_examples_for 'galera on RedHat 8 and older' do
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

      let(:os_params) do
        {
          p_additional_packages: 'nmap',
        }
      end

      case facts[:os]['family']
      when 'RedHat'
        if Puppet::Util::Package.versioncmp(facts[:os]['release']['major'], '9') >= 0
          it_configures 'galera on RedHat'
        else
          it_configures 'galera on RedHat 8 and older'
        end
      end
    end
  end
end
