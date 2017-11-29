require 'spec_helper'

describe 'galera' do
  let :params do
    {
      :galera_servers                 => ['10.2.2.1'],
      :galera_master                  => 'control1',
      :local_ip                       => '10.2.2.1',
      :bind_address                   => '10.2.2.1',
      :mysql_port                     => 3306,
      :wsrep_group_comm_port          => 4567,
      :wsrep_state_transfer_port      => 4444,
      :wsrep_inc_state_transfer_port  => 4568,
      :wsrep_sst_method               => 'rsync',
      :root_password                  => 'test',
      :override_options               => {},
      :vendor_type                    => 'percona',
      :configure_repo                 => true,
      :configure_firewall             => true,
      :deb_sysmaint_password          => 'sysmaint',
      :mysql_restart                  => false,
      :status_password                => 'nonempty',
    }
  end

  shared_examples_for 'galera' do
    it { should contain_class('galera::params') }

    context 'with default parameters' do
      it { should contain_class('galera::repo') }
      it { should contain_class('galera::firewall') }
      it { should contain_class('galera::params') }

      it { should contain_class('mysql::server').with(
        :package_name => os_params[:p_mysql_package_name],
        :root_password => params[:root_password],
        :service_name  => os_params[:mysql_service_name]
      ) }

      it { should contain_package(os_params[:p_galera_package_name]).with(:ensure => 'installed') }
      it { should contain_package(os_params[:p_additional_packages]).with(:ensure => 'installed') }

      it { should contain_xinetd__service('mysqlchk').with(
        :log_on_success => '',
        :log_on_success_operator => '=',
        :log_on_failure => nil,
      ) }

      it { should contain_group('clustercheck').with(:system => true) }
      it { should contain_user('clustercheck').with(
        :system => true,
        :gid => 'clustercheck',
      ) }
    end

    context 'when installing mariadb' do
      before { params.merge!( :vendor_type => 'mariadb') }
      it { should contain_class('mysql::server').with(
        :package_name => os_params[:m_mysql_package_name],
        :root_password => params[:root_password],
        :service_name  => os_params[:mysql_service_name]
      ) }

      it { should contain_package(os_params[:m_galera_package_name]).with(:ensure => 'installed') }
      it { should contain_package(os_params[:m_additional_packages]).with(:ensure => 'installed') }
    end

    context 'when using xtrabackup-v2' do
      before { params.merge!( :wsrep_sst_method => 'xtrabackup-v2' ) }
      it { should contain_package('percona-xtrabackup').with(:ensure => 'installed') }
    end

    context 'when managing root .my.cnf' do
      before { params.merge!( :create_root_my_cnf => true ) }
      it { should contain_class('mysql::server').with(:create_root_my_cnf => true) }
      it { should contain_exec("create #{facts[:root_home]}/.my.cnf") }
    end

    context 'when not managing root .my.cnf' do
      before { params.merge!( :create_root_my_cnf => false ) }
      it { should contain_class('mysql::server').with(:create_root_my_cnf => false) }
      it { should_not contain_exec("create #{facts[:root_home]}/.my.cnf") }
    end

    context 'when create root user is undef and the master' do
      before { params.merge!( :galera_master => facts[:fqdn] ) }
      it { should contain_class('mysql::server').with(:create_root_user => true) }
      it { should contain_mysql_user('root@localhost') }
    end

    context 'when create root user is undef and not the master' do
      before { params.merge!( :galera_master => "not_#{facts[:fqdn]}" ) }
      it { should contain_class('mysql::server').with(:create_root_user => false ) }
      it { should_not contain_mysql_user('root@localhost') }
    end

    context 'when create root user is true' do
      before { params.merge!( :create_root_user => true ) }
      it { should contain_class('mysql::server').with(:create_root_user => true) }
      it { should contain_mysql_user('root@localhost') }
    end

    context 'when create root user is false' do
      before { params.merge!( :create_root_user => false ) }
      it { should contain_class('mysql::server').with(:create_root_user => false) }
      it { should_not contain_mysql_user('root@localhost') }
    end

    context 'when installing codership' do
      before { params.merge!( :vendor_type => 'codership') }
      it { should contain_class('mysql::server').with(
        :package_name => os_params[:c_mysql_package_name],
        :root_password => params[:root_password],
        :service_name  => os_params[:c_mysql_service_name]
      ) }

      it { should contain_package(os_params[:c_galera_package_name]).with(:ensure => 'installed') }
      it { should contain_package(os_params[:c_additional_packages]).with(:ensure => 'installed') }
    end

    context 'when specifying package names' do
      before { params.merge!({
        :mysql_package_name => 'mysql-package-test',
        :galera_package_name => 'galera-package-test',
      }) }
      it { should contain_class('mysql::server').with(
        :package_name => 'mysql-package-test',
        :root_password => params[:root_password],
        :service_name  => os_params[:mysql_service_name]
      ) }

      it { should contain_package('galera-package-test').with(:ensure => 'installed') }
    end

    context 'when specifying latest packages' do
      before { params.merge!( :package_ensure => 'latest') }
      it { should contain_package(os_params[:p_galera_package_name]).with(:ensure => 'latest') }
    end

    context 'when specifying logging options' do
      before { params.merge!({
        :status_log_on_success => 'PID HOST USERID EXIT DURATION TRAFFIC',
        :status_log_on_success_operator => '-=',
        :status_log_on_failure => 'USERID',
      }) }
      it { should contain_xinetd__service('mysqlchk').with(
        :log_on_success => 'PID HOST USERID EXIT DURATION TRAFFIC',
        :log_on_success_operator => '-=',
        :log_on_failure => 'USERID'
      ) }
    end
  end

  on_supported_os.each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge({})
      end

      let (:os_params) do
        if facts[:osfamily] == 'RedHat'
          { :p_mysql_package_name  => 'Percona-XtraDB-Cluster-server-55',
            :p_galera_package_name => 'Percona-XtraDB-Cluster-galera-2',
            :p_client_package_name => 'Percona-XtraDB-Cluster-client-55',
            :p_libgalera_location  => '/usr/lib64/libgalera_smm.so',
            :p_additional_packages => 'rsync',
            :m_mysql_package_name  => 'MariaDB-Galera-server',
            :m_galera_package_name => 'galera',
            :m_client_package_name => 'MariaDB-client',
            :m_libgalera_location  => '/usr/lib64/galera/libgalera_smm.so',
            :m_additional_packages => 'rsync',
            :c_mysql_package_name  => 'mysql-wsrep-5.5',
            :c_galera_package_name => 'galera-3',
            :c_client_package_name => 'mysql-wsrep-client-5.5',
            :c_libgalera_location  => '/usr/lib64/galera-3/libgalera_smm.so',
            :c_additional_packages => 'rsync',
            :c_mysql_service_name  => 'mysqld',
            :mysql_service_name    => 'mysql',
          }
        elsif facts[:osfamily] == 'Debian'
          { :p_mysql_package_name  => 'percona-xtradb-cluster-server-5.5',
            :p_galera_package_name => 'percona-xtradb-cluster-galera-2.x',
            :p_client_package_name => 'percona-xtradb-cluster-client-5.5',
            :p_libgalera_location  => '/usr/lib/libgalera_smm.so',
            :p_additional_packages => 'rsync',
            :m_mysql_package_name  => 'mariadb-galera-server-5.5',
            :m_galera_package_name => 'galera',
            :m_client_package_name => 'mariadb-client-5.5',
            :m_libgalera_location  => '/usr/lib/galera/libgalera_smm.so',
            :m_additional_packages => 'rsync',
            :c_mysql_package_name  => 'mysql-wsrep-5.5',
            :c_galera_package_name => 'galera-3',
            :c_client_package_name => 'mysql-wsrep-client-5.5',
            :c_libgalera_location  => '/usr/lib/libgalera_smm.so',
            :c_additional_packages => 'rsync',
            :c_mysql_service_name  => 'mysql',
            :mysql_service_name    => 'mysql',
          }
        end
      end

      it_configures 'galera'
    end
  end
end
