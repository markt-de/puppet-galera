require 'spec_helper'

describe 'galera' do
  let :params do
    {
      galera_servers: ['10.2.2.1'],
      galera_master: 'control1',
      local_ip: '10.2.2.1',
      bind_address: '10.2.2.1',
      mysql_port: 3306,
      wsrep_group_comm_port: 4567,
      wsrep_state_transfer_port: 4444,
      wsrep_inc_state_transfer_port: 4568,
      wsrep_sst_method: 'rsync',
      root_password: 'test',
      override_options: {},
      vendor_type: 'percona',
      configure_repo: true,
      configure_firewall: true,
      deb_sysmaint_password: 'sysmaint',
      mysql_restart: false,
      status_password: 'nonempty',
    }
  end

  shared_examples_for 'galera' do
    context 'with default parameters' do
      it { is_expected.to contain_class('galera::repo') }
      it { is_expected.to contain_class('galera::firewall') }

      # FIXME: package names/versions need to be reworked
      # it { should contain_class('mysql::server').wit(
      #   :package_name => os_params[:p_mysql_package_name],
      #   :root_password => params[:root_password],
      #   :service_name  => os_params[:mysql_service_name]
      # ) }

      # FIXME: package names/versions need to be reworked
      # it { should contain_package(os_params[:p_galera_package_name]).with(:ensure => 'present') }
      # it { should contain_package(os_params[:p_additional_packages]).with(:ensure => 'installed') }

      it { is_expected.to contain_class('mysql::server') }

      it {
        is_expected.to contain_xinetd__service('mysqlchk').with(
          log_on_success: '',
          log_on_success_operator: '=',
          log_on_failure: nil,
        )
      }

      it { is_expected.to contain_group('clustercheck').with(system: true) }
      it {
        is_expected.to contain_user('clustercheck').with(
          system: true,
          gid: 'clustercheck',
        )
      }
    end

    context 'when installing mariadb' do
      before(:each) { params.merge!(vendor_type: 'mariadb') }
      # FIXME: package names/versions need to be reworked
      # it { should contain_class('mysql::server').with(
      #   :package_name => os_params[:m_mysql_package_name],
      #   :root_password => params[:root_password],
      #   :service_name  => os_params[:mysql_service_name]
      # ) }
      it { is_expected.to contain_class('mysql::server') }

      #      it { should contain_package(os_params[:m_galera_package_name]).with(:ensure => 'installed') }
      it { is_expected.to contain_package(os_params[:m_additional_packages]).with(ensure: 'installed') }
    end

    # FIXME: package names/versions need to be reworked
    # context 'when using xtrabackup-v2' do
    #   before { params.merge!( :wsrep_sst_method => 'xtrabackup-v2' ) }
    #   it { should contain_package(os_params[:p_xtrabackup_package]).with(:ensure => 'installed') }
    # end

    context 'when using mariabackup' do
      before(:each) { params.merge!(vendor_type: 'mariadb', wsrep_sst_method: 'mariabackup') }
      it { is_expected.to contain_package(os_params[:m_mariadb_backup_package_name]).with_ensure('installed') }
      it { is_expected.to contain_package('socat').with_ensure('installed') }
    end

    context 'when managing root .my.cnf' do
      before(:each) { params.merge!(create_root_my_cnf: true) }
      it { is_expected.to contain_class('mysql::server').with(create_root_my_cnf: true) }
      it { is_expected.to contain_exec('create /root/.my.cnf') }
    end

    context 'when not managing root .my.cnf' do
      before(:each) { params.merge!(create_root_my_cnf: false) }
      it { is_expected.to contain_class('mysql::server').with(create_root_my_cnf: false) }
      it { is_expected.not_to contain_exec('create /root/.my.cnf') }
    end

    # FIXME
    # context 'when create root user is undef and the master' do
    #   before { params.merge!( :galera_master => facts[:fqdn] ) }
    #   it { should contain_class('mysql::server').with(:create_root_user => true) }
    #   it { should contain_mysql_user('root@localhost') }
    # end

    context 'when create root user is undef and not the master' do
      before(:each) { params.merge!(galera_master: "not_#{facts[:fqdn]}") }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: false) }
      it { is_expected.not_to contain_mysql_user('root@localhost') }
    end

    # FIXME: Evaluation Error: Error while evaluating a Resource Statement, Class[Galera]: parameter 'create_root_user' expects a value of type Undef or String, got Boolean (line: 2, column: 1)
    # context 'when create root user is true' do
    #   before { params.merge!( :create_root_user => true ) }
    #   it { should contain_class('mysql::server').with(:create_root_user => true) }
    #   it { should contain_mysql_user('root@localhost') }
    # end

    context 'when create root user is false' do
      before(:each) { params.merge!(create_root_user: 'false') }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: false) }
      it { is_expected.not_to contain_mysql_user('root@localhost') }
    end

    context 'when installing codership' do
      before(:each) { params.merge!(vendor_type: 'codership') }
      # FIXME: package names/versions need to be reworked
      # it { should contain_class('mysql::server').with(
      #   :package_name => os_params[:c_mysql_package_name],
      #   :root_password => params[:root_password],
      #   :service_name  => os_params[:mysql_service_name]
      # ) }
      it { is_expected.to contain_class('mysql::server') }

      it { is_expected.to contain_package(os_params[:c_galera_package_name]).with(ensure: 'present') }
      it { is_expected.to contain_package(os_params[:c_additional_packages]).with(ensure: 'installed') }
    end

    context 'when specifying package names' do
      before(:each) do
        params.merge!(mysql_package_name: 'mysql-package-test',
                      galera_package_name: 'galera-package-test')
      end
      it {
        is_expected.to contain_class('mysql::server').with(
          package_name: 'mysql-package-test',
          root_password: params[:root_password],
          service_name: os_params[:mysql_service_name],
        )
      }

      it { is_expected.to contain_package('galera-package-test').with(ensure: 'present') }
    end

    # FIXME: package names/versions need to be reworked
    # context 'when specifying latest packages' do
    #   before { params.merge!( :package_ensure => 'latest') }
    #   it { should contain_package(os_params[:p_galera_package_name]).with(:ensure => 'present') }
    # end

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

  on_supported_os(facterversion: '3.11').each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts.merge({})
      end

      let(:os_params) do
        if facts[:osfamily] == 'RedHat'
          { p_mysql_package_name: 'Percona-XtraDB-Cluster-server-55',
            p_galera_package_name: 'Percona-XtraDB-Cluster-galera-2',
            p_client_package_name: 'Percona-XtraDB-Cluster-client-55',
            p_libgalera_location: '/usr/lib64/libgalera_smm.so',
            p_additional_packages: 'rsync',
            p_xtrabackup_package: 'percona-xtrabackup',
            m_mysql_package_name: 'MariaDB-Galera-server',
            m_galera_package_name: 'galera',
            m_client_package_name: 'MariaDB-client',
            m_libgalera_location: '/usr/lib64/galera/libgalera_smm.so',
            m_additional_packages: 'rsync',
            c_mysql_package_name: 'mysql-wsrep-5.5',
            c_galera_package_name: 'galera-3',
            c_client_package_name: 'mysql-wsrep-client-5.5',
            c_libgalera_location: '/usr/lib64/galera-3/libgalera_smm.so',
            c_additional_packages: 'rsync',
            mysql_service_name: 'mysql',
            m_mariadb_backup_package_name: 'MariaDB-backup' }
        elsif facts[:osfamily] == 'Debian'
          if facts[:os]['release']['major'] == '8'
            {
              p_mysql_package_name: 'percona-xtradb-cluster-server-5.5',
              p_galera_package_name: 'percona-xtradb-cluster-galera-2.x',
              p_client_package_name: 'percona-xtradb-cluster-client-5.5',
              p_libgalera_location: '/usr/lib/libgalera_smm.so',
              p_additional_packages: 'rsync',
              p_xtrabackup_package: 'percona-xtrabackup',
              m_mysql_package_name: 'mariadb-galera-server-5.5',
              m_galera_package_name: 'galera',
              m_client_package_name: 'mariadb-client-5.5',
              m_libgalera_location: '/usr/lib/galera/libgalera_smm.so',
              m_additional_packages: 'rsync',
              c_mysql_package_name: 'mysql-wsrep-5.5',
              c_galera_package_name: 'galera-3',
              c_client_package_name: 'mysql-wsrep-client-5.5',
              c_libgalera_location: '/usr/lib/libgalera_smm.so',
              c_additional_packages: 'rsync',
              mysql_service_name: 'mysql',
              m_mariadb_backup_package_name: 'mariadb-backup',
            } else {
              p_mysql_package_name: 'percona-xtradb-cluster-server-5.7',
              p_galera_package_name: 'percona-xtradb-cluster-galera-3.x',
              p_client_package_name: 'percona-xtradb-cluster-client-5.7',
              p_libgalera_location: '/usr/lib/libgalera_smm.so',
              p_additional_packages: 'rsync',
              p_xtrabackup_package: 'percona-xtrabackup-24',
              m_mysql_package_name: 'mariadb-server-10.3',
              m_galera_package_name: 'mariadb',
              m_client_package_name: 'mariadb-client-10.3',
              m_libgalera_location: '/usr/lib/galera/libgalera_smm.so',
              m_additional_packages: 'rsync',
              c_mysql_package_name: 'mysql-wsrep-5.7',
              c_galera_package_name: 'galera-3',
              c_client_package_name: 'mysql-wsrep-client-5.7',
              c_libgalera_location: '/usr/lib/libgalera_smm.so',
              c_additional_packages: 'rsync',
              mysql_service_name: 'mysql',
              m_mariadb_backup_package_name: 'mariadb-backup',
            }
          end
        end
      end

      it_configures 'galera'
    end
  end
end
