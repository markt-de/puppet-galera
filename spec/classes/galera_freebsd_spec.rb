require 'spec_helper'

describe 'galera' do
  let :params do
    {
      arbitrator_config_file: '/etc/default/garb',
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
      root_password: 'test',
      status_password: 'nonempty',
      vendor_type: 'percona',
      vendor_version: '5.7',
      wsrep_group_comm_port: 4567,
      wsrep_inc_state_transfer_port: 4568,
      wsrep_sst_method: 'rsync',
      wsrep_state_transfer_port: 4444,
    }
  end

  shared_examples_for 'galera on FreeBSD' do
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
        facts.merge({})
      end

      case facts[:osfamily]
      when 'FreeBSD'
        it_configures 'galera on FreeBSD'
      end
    end
  end
end
