class galera::params {
 $server_csl = join($galera::galera_servers, ',')

    if ($::osfamily == 'RedHat') {
        $mysql_service_name = 'mysql'
        if $galera::vendor_type == 'percona' {
            $mysql_package_name = 'Percona-XtraDB-Cluster-server-55'
            $galera_package_name = 'Percona-XtraDB-Cluster-galera-2'
            $client_package_name = 'Percona-XtraDB-Cluster-client-55'
            $additional_packages = 'percona-xtrabackup'
            $libgalera_location = '/usr/lib64/libgalera_smm.so'
        }
        elsif $galera::vendor_type == 'mariadb' {
            $mysql_package_name = 'MariaDB-Galera-server'
            $galera_package_name = 'galera'
            $client_package_name = 'MariaDB-client'
            $libgalera_location = '/usr/lib64/galera/libgalera_smm.so'
            $additional_packages = 'rsync'
        }

        $rundir = '/var/run/mysqld'

    }
    elsif ($::osfamily == 'Debian'){
        $mysql_service_name = 'mysql'
        if $galera::vendor_type == 'percona' {
            $mysql_package_name = 'percona-xtradb-cluster-server-5.5'
            $galera_package_name = 'percona-xtradb-cluster-galera-2.x'
            $client_package_name = 'percona-xtradb-cluster-client-5.5'
            $additional_packages = 'percona-xtrabackup'
            $libgalera_location = '/usr/lib/libgalera_smm.so'
        }
        elsif $galera::vendor_type == 'mariadb' {
            $mysql_package_name = 'mariadb-galera-server-5.5'
            $galera_package_name = 'galera'
            $client_package_name = 'mariadb-client-5.5'
            $additional_packages = 'rsync'
            $libgalera_location = '/usr/lib/galera/libgalera_smm.so'
        }
        $rundir = '/var/run/mysqld'
    }
    else {
        fail('This distribution is not supported by the puppet-galera module')
    }
 $default_options = {
      'mysqld' => {
          'bind-address'       => $galera::bind_address,
          'wsrep_node_address' => $galera::local_ip,
          'wsrep_provider'     => $galera::params::libgalera_location,
          'wsrep_cluster_address' => "gcomm://${server_csl}",
          'wsrep_slave_threads' => '8',
          'wsrep_sst_method' => 'rsync',
          'binlog_format' => 'ROW',
          'default_storage_engine' => 'InnoDB',
          'innodb_locks_unsafe_for_binlog' => '1',
          'innodb_autoinc_lock_mode' => '2',
          'query_cache_size' => '0',
          'query_cache_type' => '0',
          'wsrep_node_incoming_address' => $galera::local_ip,
          'wsrep_sst_receive_address' => $galera::local_ip
      }
    }

}
