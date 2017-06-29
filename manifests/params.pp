# == Class: galera::params
#
# Parameters for the galera module
#
class galera::params {
  $server_csl = join($galera::galera_servers, ',')

  if $galera::vendor_type == 'percona' {
    $bootstrap_command = '/etc/init.d/mysql bootstrap-pxc'
  } elsif ($galera::vendor_type == 'mariadb' or $galera::vendor_type == 'codership') {
    if ($::osfamily == 'RedHat' and versioncmp($::operatingsystemrelease, '7') >= 0 and
      $galera::vendor_version and versioncmp($galera::vendor_version, '10.0') == 1
    ) {
      # We have systemd and we should use the binary
      $bootstrap_command = '/usr/bin/galera_new_cluster'
    } else {
      $bootstrap_command = 'service mysql bootstrap'
    }
  } elsif $galera::vendor_type == 'osp5' {
    # mysqld log part is a workaround for a packaging bug
    # to be removed when packages are fixed
    $bootstrap_command = 'touch /var/log/mysqld.log ; chown mysql:mysql /var/log/mysqld.log ; systemctl start mysqld'
  }

  if ($::osfamily == 'RedHat') {
    if $galera::vendor_type == 'percona' {
      if $galera::vendor_version == '5.6' {
        $mysql_package_name_internal = 'Percona-XtraDB-Cluster-server-56'
        $galera_package_name_internal = 'Percona-XtraDB-Cluster-galera-3'
        $client_package_name_internal = 'Percona-XtraDB-Cluster-client-56'
      }
      elsif $galera::vendor_version == '5.7' {
        $mysql_package_name_internal = 'Percona-XtraDB-Cluster-server-57'
        $galera_package_name_internal = 'Percona-XtraDB-Cluster-galera-3'
        $client_package_name_internal = 'Percona-XtraDB-Cluster-client-57'
      }
      else {
        $mysql_package_name_internal = 'Percona-XtraDB-Cluster-server-55'
        $galera_package_name_internal = 'Percona-XtraDB-Cluster-galera-2'
        $client_package_name_internal = 'Percona-XtraDB-Cluster-client-55'
      }
      $mysql_service_name_internal = 'mysql'
      $libgalera_location = '/usr/lib64/libgalera_smm.so'
    }
    elsif $galera::vendor_type == 'mariadb' {
      $mysql_service_name_internal = 'mysql'
      $galera_package_name_internal = 'galera'
      $client_package_name_internal = 'MariaDB-client'
      $libgalera_location = '/usr/lib64/galera/libgalera_smm.so'
      if $galera::vendor_version and versioncmp($galera::vendor_version, '10.0') == 1 {
        $mysql_package_name_internal = 'MariaDB-server'
      } else {
        $mysql_package_name_internal = 'MariaDB-Galera-server'
      }
    }
    elsif $galera::vendor_type == 'codership' {
      if $galera::vendor_version == '5.6' {
        $mysql_package_name_internal = 'mysql-wsrep-5.6'
        $client_package_name_internal = 'mysql-wsrep-client-5.6'
      }
      elsif $galera::vendor_version == '5.7' {
        $mysql_package_name_internal = 'mysql-wsrep-5.7'
        $client_package_name_internal = 'mysql-wsrep-client-5.7'
      }
      else {
        $mysql_package_name_internal = 'mysql-wsrep-5.5'
        $client_package_name_internal = 'mysql-wsrep-client-5.5'
      }
      $mysql_service_name_internal = 'mysqld'
      $galera_package_name_internal = 'galera-3'
      $libgalera_location = '/usr/lib64/galera-3/libgalera_smm.so'
    }
    elsif $galera::vendor_type == 'osp5' {
      $mysql_service_name_internal  = 'mariadb'
      $mysql_package_name_internal  = 'mariadb-galera-server'
      $galera_package_name_internal = 'galera'
      $client_package_name_internal = 'mariadb'
      $libgalera_location           = '/usr/lib64/galera/libgalera_smm.so'
    }
    $osr_array = split($::operatingsystemrelease,'[\/\.]')
    $distrelease = $osr_array[0]


    $rundir = '/var/run/mysqld'

  }
  elsif ($::osfamily == 'Debian'){
    $mysql_service_name_internal = 'mysql'
    if $galera::vendor_type == 'percona' {
      if $galera::vendor_version == '5.6' {
        $mysql_package_name_internal = 'percona-xtradb-cluster-server-5.6'
        $galera_package_name_internal = 'percona-xtradb-cluster-galera-3.x'
        $client_package_name_internal = 'percona-xtradb-cluster-client-5.6'
      } elsif $galera::vendor_version == '5.7' {
        $mysql_package_name_internal = 'percona-xtradb-cluster-server-5.7'
        $galera_package_name_internal = 'percona-xtradb-cluster-galera-3.x'
        $client_package_name_internal = 'percona-xtradb-cluster-client-5.7'
      } else {
        $mysql_package_name_internal = 'percona-xtradb-cluster-server-5.5'
        $galera_package_name_internal = 'percona-xtradb-cluster-galera-2.x'
        $client_package_name_internal = 'percona-xtradb-cluster-client-5.5'
      }
      $libgalera_location = '/usr/lib/libgalera_smm.so'
    }
    elsif $galera::vendor_type == 'mariadb' {
      $mysql_package_name_internal = 'mariadb-galera-server-5.5'
      $galera_package_name_internal = 'galera'
      $client_package_name_internal = 'mariadb-client-5.5'
      $libgalera_location = '/usr/lib/galera/libgalera_smm.so'
    }
    elsif $galera::vendor_type == 'codership' {
      if $galera::vendor_version == '5.6' {
        $mysql_package_name_internal = 'mysql-wsrep-5.6'
        $client_package_name_internal = 'mysql-wsrep-client-5.6'
      }
      elsif $galera::vendor_version == '5.7' {
        $mysql_package_name_internal = 'mysql-wsrep-5.7'
        $client_package_name_internal = 'mysql-wsrep-client-5.7'
      }
      else {
        $mysql_package_name_internal = 'mysql-wsrep-5.5'
        $client_package_name_internal = 'mysql-wsrep-client-5.5'
      }
      $galera_package_name_internal = 'galera-3'
      $libgalera_location = '/usr/lib/galera/libgalera_smm.so'
    }
    elsif $galera::vendor_type == 'osp5' {
      fail('OSP5 is only supported on RHEL platforms.')
    }

    $rundir = '/var/run/mysqld'
  }
  else {
    fail('This distribution is not supported by the puppet-galera module')
  }

  # add auth credentials for SST methods which need them:
  #  mysqldump, xtrabackup, and xtrabackup-v2
  if ($galera::wsrep_sst_method == 'rsync') {
    $additional_packages = 'rsync'
  } elsif ($galera::wsrep_sst_method in
    [ 'xtrabackup',
    'xtrabackup-v2' ]) {

    if $galera::vendor_version == '5.7' {
      $additional_packages = 'percona-xtrabackup-24'
    } else {
      $additional_packages = 'percona-xtrabackup'
    }
  }
  if ($galera::wsrep_sst_method in [ 'skip', 'rsync' ]) {
    $wsrep_sst_auth = undef
  }
  elsif ($galera::wsrep_sst_method in
    [ 'mysqldump',
    'xtrabackup',
    'xtrabackup-v2' ])
  {
    $wsrep_sst_auth = "root:${galera::root_password}"
  }
  else {
    $wsrep_sst_auth = undef
    warning("wsrep_sst_method of ${galera::wsrep_sst_method} not recognized")
  }

  $default_options = {
    'mysqld' => {
      'bind-address'                    => $galera::bind_address,
      'wsrep_node_address'              => $galera::local_ip,
      'wsrep_provider'                  => $galera::params::libgalera_location,
      'wsrep_cluster_address'           => "gcomm://${server_csl}",
      'wsrep_slave_threads'             => '8',
      'wsrep_sst_method'                => $galera::wsrep_sst_method,
      'wsrep_sst_auth'                  => "\"${wsrep_sst_auth}\"",
      'binlog_format'                   => 'ROW',
      'default_storage_engine'          => 'InnoDB',
      'innodb_locks_unsafe_for_binlog'  => '1',
      'innodb_autoinc_lock_mode'        => '2',
      'query_cache_size'                => '0',
      'query_cache_type'                => '0',
      'wsrep_node_incoming_address'     => $galera::local_ip,
      'wsrep_sst_receive_address'       => $galera::local_ip,
      'wsrep_on'                        => 'ON',
    }
  }

  $mysql_package_name = pick(
    $::galera::mysql_package_name,
    $mysql_package_name_internal
  )
  $galera_package_name = pick(
    $::galera::galera_package_name,
    $galera_package_name_internal
  )
  $client_package_name = pick(
    $::galera::client_package_name,
    $client_package_name_internal
  )
  $mysql_service_name = pick(
    $::galera::mysql_service_name,
    $mysql_service_name_internal
  )
}
