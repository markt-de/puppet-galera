require 'spec_helper'

describe 'galera' do
  let :params do
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
      vendor_version: '5.7',
      wsrep_group_comm_port: 4567,
      wsrep_inc_state_transfer_port: 4568,
      wsrep_sst_method: 'rsync',
      wsrep_state_transfer_port: 4444,
    }
  end

  shared_examples_for 'galera' do
    context 'with default parameters (percona)' do
      it { is_expected.to contain_class('galera::firewall') }
      it { is_expected.to contain_class('galera::repo') }
      it { is_expected.to contain_class('galera::status') }
      it { is_expected.to contain_class('galera::validate') }

      it { is_expected.to contain_firewall('4567 galera accept tcp') }

      it {
        is_expected.to contain_class('mysql::server').with(
          package_name: os_params[:p_mysql_package_name],
          root_password: params[:root_password],
          service_name: os_params[:p_mysql_service_name],
        )
      }

      it { is_expected.to contain_package(os_params[:nmap_package_name]).with(ensure: 'installed') }
      it { is_expected.to contain_package(os_params[:p_galera_package_name]).with(ensure: 'absent') }
      it { is_expected.to contain_package(os_params[:p_additional_packages]).with(ensure: 'installed') }

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
      it { is_expected.to contain_file('/usr/local/bin/clustercheck').with_content(%r{HTTP/1.1 200 OK}) }

      it { is_expected.to contain_file('mysql-config-file').with_content(%r{wsrep_cluster_address = gcomm://10.2.2.1:4567/}) }
      it { is_expected.to contain_file('mysql-config-file').with_content(%r{wsrep_cluster_name = testcluster}) }
      it { is_expected.to contain_file('/var/run/mysqld').with(ensure: 'directory') }
    end

    context 'when node is the master' do
      before(:each) { params.merge!(galera_master: facts[:fqdn]) }
      it { is_expected.to contain_exec('bootstrap_galera_cluster') }
    end

    context 'when node is not the master' do
      before(:each) { params.merge!(galera_master: "not_#{facts[:fqdn]}") }
      it { is_expected.not_to contain_exec('bootstrap_galera_cluster') }
    end

    context 'when installing mariadb' do
      before(:each) { params.merge!(vendor_type: 'mariadb', vendor_version: '10.3') }
      it {
        is_expected.to contain_class('mysql::server').with(
          package_name: os_params[:m_mysql_package_name],
          root_password: params[:root_password],
          service_name: os_params[:m_mysql_service_name],
        )
      }
      it { is_expected.to contain_class('mysql::server') }

      it { is_expected.to contain_package(os_params[:nmap_package_name]).with(ensure: 'installed') }
      it { is_expected.to contain_package(os_params[:m_galera_package_name]).with(ensure: 'present') }
      it { is_expected.to contain_package(os_params[:m_additional_packages]).with(ensure: 'installed') }
    end

    context 'when using xtrabackup' do
      before(:each) { params.merge!(wsrep_sst_method: 'xtrabackup') }
      it {
        if os_params[:p_xtrabackup_package] != 'NONE'
          is_expected.to contain_package(os_params[:p_xtrabackup_package]).with(ensure: 'installed')
        end
      }
    end

    context 'when using xtrabackup-v2' do
      before(:each) { params.merge!(wsrep_sst_method: 'xtrabackup-v2') }
      it {
        if os_params[:p_xtrabackup_package] != 'NONE'
          is_expected.to contain_package(os_params[:p_xtrabackup_package]).with(ensure: 'installed')
        end
      }
    end

    context 'when using mariabackup' do
      before(:each) { params.merge!(vendor_type: 'mariadb', vendor_version: '10.3', wsrep_sst_method: 'mariabackup') }
      it {
        if os_params[:m_mariadb_backup_package_name] != 'NONE'
          is_expected.to contain_package(os_params[:m_mariadb_backup_package_name]).with_ensure('installed')
        end
      }
      it { is_expected.to contain_package('socat').with_ensure('installed') }
    end

    context 'when managing root .my.cnf' do
      before(:each) { params.merge!(create_root_my_cnf: true) }
      it { is_expected.to contain_class('mysql::server').with(create_root_my_cnf: true) }
      it { is_expected.to contain_exec('create .my.cnf for user root') }
    end

    context 'when not managing root .my.cnf' do
      before(:each) { params.merge!(create_root_my_cnf: false) }
      it { is_expected.to contain_class('mysql::server').with(create_root_my_cnf: false) }
      it { is_expected.not_to contain_exec('create .my.cnf for user root') }
    end

    context 'when create_root_user=undef (default) and the master' do
      before(:each) { params.merge!(galera_master: facts[:fqdn]) }
      it { is_expected.to contain_class('galera').with(create_root_user: nil) }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: true) }
      it { is_expected.to contain_mysql_user('root@localhost') }
    end

    context 'when create_root_user=undef (default) and not the master' do
      before(:each) { params.merge!(galera_master: "not_#{facts[:fqdn]}") }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: false) }
      it { is_expected.not_to contain_mysql_user('root@localhost') }
    end

    context 'when create_root_user=true' do
      before(:each) { params.merge!(create_root_user: true) }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: true) }
      it { is_expected.to contain_mysql_user('root@localhost') }
    end

    context 'when create root user is false' do
      before(:each) { params.merge!(create_root_user: false) }
      it { is_expected.to contain_class('mysql::server').with(create_root_user: false) }
      it { is_expected.not_to contain_mysql_user('root@localhost') }
    end

    context 'when create_status_user=true (default)' do
      it { is_expected.to contain_mysql_user('clustercheck@localhost') }
      it { is_expected.to contain_mysql_user('clustercheck@%') }
      it { is_expected.to contain_mysql_grant('clustercheck@localhost/*.*') }
      it { is_expected.to contain_mysql_grant('clustercheck@%/*.*') }
    end

    context 'when create_status_user=false' do
      before(:each) { params.merge!(create_status_user: false) }
      it { is_expected.not_to contain_mysql_user('clustercheck@localhost') }
      it { is_expected.not_to contain_mysql_user('clustercheck@%') }
      it { is_expected.not_to contain_mysql_grant('clustercheck@localhost/*.*') }
      it { is_expected.not_to contain_mysql_grant('clustercheck@%/*.*') }
    end

    context 'when status_allow=example' do
      before(:each) { params.merge!(status_allow: 'example') }
      it { is_expected.to contain_mysql_user('clustercheck@localhost') }
      it { is_expected.to contain_mysql_user('clustercheck@example') }
      it { is_expected.not_to contain_mysql_user('clustercheck@%') }
      it { is_expected.to contain_mysql_grant('clustercheck@localhost/*.*') }
      it { is_expected.to contain_mysql_grant('clustercheck@example/*.*') }
    end

    context 'when validate_connection=true (default)' do
      it { is_expected.to contain_class('galera::validate') }
      it { is_expected.to contain_exec('validate_connection') }
    end

    context 'when validate_connection=false' do
      before(:each) { params.merge!(validate_connection: false) }
      it { is_expected.not_to contain_class('galera::validate') }
      it { is_expected.not_to contain_exec('validate_connection') }
    end

    context 'when installing codership' do
      before(:each) { params.merge!(vendor_type: 'codership') }
      it {
        is_expected.to contain_class('mysql::server').with(
          package_name: os_params[:c_mysql_package_name],
          root_password: params[:root_password],
          service_name: os_params[:c_mysql_service_name],
        )
      }
      it { is_expected.to contain_class('mysql::server') }

      it { is_expected.to contain_package(os_params[:c_galera_package_name]).with(ensure: 'present') }
      it { is_expected.to contain_package(os_params[:c_additional_packages]).with(ensure: 'installed') }
    end

    context 'when specifying package names' do
      before(:each) do
        params.merge!(mysql_package_name: 'mysql-package-test',
                      galera_package_name: 'galera-package-test',
                      galera_package_ensure: 'present')
      end
      it {
        is_expected.to contain_class('mysql::server').with(
          package_name: 'mysql-package-test',
          root_password: params[:root_password],
          service_name: os_params[:p_mysql_service_name],
        )
      }

      it { is_expected.to contain_package('galera-package-test').with(ensure: 'present') }
    end

    context 'when package_ensure=present (default)' do
      it { is_expected.to contain_package(os_params[:p_galera_package_name]).with(ensure: 'absent') }
      it {
        is_expected.to contain_class('mysql::server').with(
          package_ensure: 'present',
          package_name: os_params[:p_mysql_package_name],
        )
      }
    end

# Class[Mysql::Server]: parameter 'package_ensure' expects a match for Variant[Enum['absent', 'present']
#
#   context 'when package_ensure=latest' do
#     before(:each) { params.merge!(package_ensure: 'latest') }
#     it { is_expected.to contain_package(os_params[:p_galera_package_name]).with(ensure: 'absent') }
#     it {
#       is_expected.to contain_class('mysql::server').with(
#         package_ensure: 'latest',
#         package_name: os_params[:p_mysql_package_name],
#       )
#     }
#   end
#
#   context 'when galera_package_ensure=latest' do
#     before(:each) { params.merge!(galera_package_ensure: 'latest') }
#     it { is_expected.to contain_package(os_params[:p_galera_package_name]).with(ensure: 'latest') }
#   end

    context 'when configure_firewall=false' do
      before(:each) { params.merge!(configure_firewall: false) }
      it { is_expected.not_to contain_class('galera::firewall') }
      it { is_expected.not_to contain_firewall('4567 galera accept tcp') }
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

      let(:os_params) do
        if facts[:osfamily] == 'RedHat'
          m_mysql_service_name = if Puppet::Util::Package.versioncmp(facts[:operatingsystemmajrelease], '7') >= 0
                                   'mariadb'
                                 else
                                   'mysql'
                                 end
          { c_additional_packages: 'rsync',
            c_client_package_name: 'mysql-wsrep-client-5.7',
            c_galera_package_name: 'galera-3',
            c_libgalera_location: '/usr/lib64/galera-3/libgalera_smm.so',
            c_mysql_package_name: 'mysql-wsrep-5.7',
            c_mysql_service_name: 'mysqld',
            m_additional_packages: 'rsync',
            m_client_package_name: 'MariaDB-client',
            m_galera_package_name: 'galera',
            m_libgalera_location: '/usr/lib64/galera/libgalera_smm.so',
            m_mariadb_backup_package_name: 'MariaDB-backup',
            m_mysql_package_name: 'MariaDB-server',
            m_mysql_service_name: m_mysql_service_name,
            p_additional_packages: 'rsync',
            p_client_package_name: 'Percona-XtraDB-Cluster-client-57',
            p_galera_package_name: 'Percona-XtraDB-Cluster-galera-3',
            p_libgalera_location: '/usr/lib64/libgalera_smm.so',
            p_mysql_package_name: 'Percona-XtraDB-Cluster-57',
            p_mysql_service_name: 'mysql',
            p_xtrabackup_package: 'percona-xtrabackup-24',
            nmap_package_name: 'nmap' }
        elsif facts[:osfamily] == 'Debian'
          { c_additional_packages: 'rsync',
            c_client_package_name: 'mysql-wsrep-client-5.7',
            c_galera_package_name: 'galera-3',
            c_libgalera_location: '/usr/lib/libgalera_smm.so',
            c_mysql_package_name: 'mysql-wsrep-5.7',
            c_mysql_service_name: 'mysql',
            m_additional_packages: 'rsync',
            m_client_package_name: 'mariadb-client-10.3',
            m_galera_package_name: 'galera-3',
            m_libgalera_location: '/usr/lib/galera/libgalera_smm.so',
            m_mariadb_backup_package_name: 'mariadb-backup',
            m_mysql_package_name: 'mariadb-server-10.3',
            m_mysql_service_name: 'mysql',
            p_additional_packages: 'rsync',
            p_client_package_name: 'percona-xtradb-cluster-client-5.7',
            p_galera_package_name: 'percona-xtradb-cluster-galera-3.x',
            p_libgalera_location: '/usr/lib/galera/libgalera_smm.so',
            p_mysql_package_name: 'percona-xtradb-cluster-server-5.7',
            p_mysql_service_name: 'mysql',
            p_xtrabackup_package: 'percona-xtrabackup-24',
            mysql_service_name: 'mysql',
            nmap_package_name: 'nmap' }
        elsif facts[:osfamily] == 'FreeBSD'
          { c_additional_packages: 'rsync',
            c_client_package_name: 'mysql57-client',
            c_galera_package_name: 'galera',
            c_libgalera_location: '/usr/local/lib/libgalera_smm.so',
            c_mysql_package_name: 'mysqlwsrep57-server',
            c_mysql_service_name: 'mysql-server',
            m_additional_packages: 'rsync',
            m_client_package_name: 'mariadb103-client',
            m_galera_package_name: 'galera',
            m_libgalera_location: '/usr/local/lib/libgalera_smm.so',
            m_mariadb_backup_package_name: 'NONE',
            m_mysql_package_name: 'mariadb103-server',
            m_mysql_service_name: 'mysql-server',
            p_additional_packages: 'rsync',
            p_client_package_name: 'UNSUPPORTED-client_package_name',
            p_galera_package_name: 'UNSUPPORTED-galera_package_name',
            p_libgalera_location: '/UNSUPPORTED-libgalera_location',
            p_mysql_package_name: 'UNSUPPORTED-mysql_package_name',
            p_mysql_service_name: 'UNSUPPORTED-mysql_service_name',
            p_xtrabackup_package: 'NONE',
            mysql_service_name: 'mysql-server',
            nmap_package_name: 'nmap' }
        end
      end

      it_configures 'galera'
    end
  end
end
