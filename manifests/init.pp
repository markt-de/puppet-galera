class galera(
    $galera_servers,
    $galera_master,
    $local_ip = $::ipaddress_eth1,
    $mysql_port = 3306,
    $wsrep_group_comm_port = 4567,
    $wsrep_state_transfer_port = 4444,
    $wsrep_inc_state_transfer_port = 4568,
    $rootpassword = 'test',
    $override_options = {},
    $vendor_type = 'percona',
    $configure_repo = true,
    $configure_firewall = true,
)
{ 
    if $configure_repo {
        include galera::repo
    }

    if $configure_firewall {
        include galera::firewall
    }

    # Debian machines need some help
    if ($::osfamily == 'Debian') {
        include galera::debian
    }

    include galera::params

    $options = mysql_deepmerge($galera::params::default_options, $override_options)

    if $::fqdn == $galera_master {
        $root_password_real = $rootpassword
    } else {
        $root_password_real = 'UNSET'
    }

    class { 'mysql::server':
      package_name => $galera::params::mysql_package_name,
      override_options => $options,
      root_password => $root_password_real,
      service_name => $galera::params::mysql_service_name, 
    }

    file { $galera::params::rundir:
      ensure => directory,
      owner  => 'mysql',
      group  => 'mysql',
      require => Class['mysql::server::install'],
      before => Class['mysql::server::config']
    }

    if $galera::params::additional_packages {
        package{ $galera::params::additional_packages:
          ensure => latest,
          require => Anchor['mysql::server::start'],
          before  => Class['mysql::server::install']
        }
    }

    package{[
            $galera::params::galera_package_name,
            $galera::params::client_package_name,
            ] :
      ensure => latest,
      require => Anchor['mysql::server::start'],
      before  => Class['mysql::server::install']
    }

    if $fqdn == $galera_master {
        # If there are no other servers up and we are the master, the cluster
        # needs to be bootstrapped. This happens before the service is managed 
        $server_list = join($galera_servers, ' ')
        exec { 'bootstrap_galera_cluster':
            command => "service mysql start --wsrep_cluster_address=gcomm://",
            onlyif => "ret=1; for i in ${server_list}; do /bin/nc -z \$i ${wsrep_group_comm_port}; if [ \"\$?\" = \"0\" ]; then ret=0; fi; done; /bin/echo \$ret | /bin/grep 1 -q",
            require => Class['mysql::server::config'],
            before => [Class['mysql::server::service'], Service['mysqld']],
            provider => shell,
            path => '/usr/bin:/bin:/usr/sbin:/sbin'
        }

        database_user { "clustercheckuser@localhost":
          ensure => "present",
          password_hash => mysql_password("clustercheckpassword!"), # can not change password in clustercheck script
          provider      => 'mysql',
          require => [ File["/root/.my.cnf"], Service['mysqld']],
        }

    }
}
