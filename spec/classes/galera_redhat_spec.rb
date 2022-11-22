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

  shared_examples_for 'galera on RedHat' do
    context 'when installing percona' do
      it { is_expected.to contain_class('galera::redhat') }
      it { is_expected.to contain_package(os_params[:p_additional_packages]).with(ensure: 'installed') }
      it { is_expected.to contain_service('mysql@bootstrap') }
      it { is_expected.to contain_file('/lib/systemd/system/mysqlchk.socket').with_content(%r{ListenStream=9200}) }
      it {
        is_expected.to contain_file('/lib/systemd/system/mysqlchk@.service')
          .with_content(%r{User=clustercheck})
          .with_content(%r{Group=clustercheck})
          .with_content(%r{ExecStart=/usr/local/bin/clustercheck})
          .with_content(%r{StandardInput=socket})
      }
      it {
        is_expected.to contain_exec('mysqlchk-systemd-reload').with(
          'command'     => 'systemctl daemon-reload',
          'path'        => ['/usr/bin', '/bin', '/usr/sbin'],
          'refreshonly' => true,
        )
      }
    end

    context 'when node is the master' do
      before(:each) { params.merge!(galera_master: facts[:fqdn]) }
      it { is_expected.to contain_exec('bootstrap_galera_cluster').with_command(%r{systemctl start mysql@bootstrap.service}) }
    end

    context 'when installing mariadb' do
      before(:each) { params.merge!(vendor_type: 'mariadb', vendor_version: '10.3') }

      it { is_expected.to contain_file('/var/log/mariadb') }
      it { is_expected.to contain_file('/var/run/mariadb') }
    end

    context 'when status_port=12345' do
      before(:each) do
        params.merge!(status_port: 12_345)
      end
      it { is_expected.to contain_file('/lib/systemd/system/mysqlchk.socket').with_content(%r{ListenStream=12345}) }
    end
  end

  shared_examples_for 'galera on RedHat 6' do
    context 'when node is the master' do
      before(:each) { params.merge!(galera_master: facts[:fqdn]) }
      it { is_expected.to contain_exec('bootstrap_galera_cluster').with_command(%r{/etc/init.d/mysql bootstrap-pxc}) }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts.merge({})
      end

      let(:os_params) do
        {
          p_additional_packages: 'nmap',
        }
      end

      case facts[:osfamily]
      when 'RedHat'
        if Puppet::Util::Package.versioncmp(facts[:operatingsystemmajrelease], '7') >= 0
          it_configures 'galera on RedHat'
        elsif facts[:operatingsystemmajrelease] == '6'
          it_configures 'galera on RedHat 6'
        end
      end
    end
  end
end
