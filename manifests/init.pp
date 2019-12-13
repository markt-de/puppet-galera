# == Class galera
#
# Installs MySQL/MariaDB with galera
#
class galera(
  # parameters that need to be evaluated early
  Enum['codership', 'mariadb', 'osp5', 'percona'] $vendor_type,
  # required parameters
  String $bind_address,
  Boolean $configure_firewall,
  Boolean $configure_repo,
  Boolean $create_root_my_cnf,
  Boolean $create_status_user,
  String $deb_sysmaint_password,
  Hash $default_options,
  String $galera_master,
  String $galera_package_ensure,
  String $grep_binary,
  String $local_ip,
  Boolean $manage_additional_packages,
  Boolean $manage_package_nmap,
  String $mysql_binary,
  Integer $mysql_port,
  Boolean $mysql_restart,
  Hash $override_options,
  String $package_ensure,
  Boolean $purge_conf_dir,
  String $root_password,
  String $rundir,
  Boolean $service_enabled,
  String $status_allow,
  Integer $status_available_when_donor,
  Integer $status_available_when_readonly,
  Boolean $status_check,
  String $status_host,
  String $status_log_on_success_operator,
  String $status_password,
  Integer $status_port,
  String $status_user,
  Boolean $validate_connection,
  Integer $wsrep_group_comm_port,
  Integer $wsrep_inc_state_transfer_port,
  String $wsrep_sst_auth,
  Enum['mariabackup', 'mysqldump', 'rsync', 'skip', 'xtrabackup', 'xtrabackup-v2'] $wsrep_sst_method,
  Integer $wsrep_state_transfer_port,
  # optional parameters
  # (some of them are actually required, see notes)
  Optional[Array] $additional_packages = undef,
  Optional[String] $bootstrap_command = undef,
  Optional[String] $client_package_name = undef,
  Optional[String] $create_root_user = undef,
  Optional[String] $galera_package_name = undef,
  Optional[Array] $galera_servers = undef,
  Optional[String] $libgalera_location = undef,
  Optional[String] $mysql_package_name = undef,
  Optional[String] $mysql_service_name = undef,
  Optional[String] $status_log_on_failure = undef,
  Optional[String] $status_log_on_success = undef,
  Optional[String] $vendor_version = undef,
) {
  # Fetch appropiate default values from module data, depending on the values
  # of $vendor_type and $vendor_version.
  # XXX: Originally this was supposed to take place when evaluating the class
  # parameters. Now this is basically an ugly compatibility layer to support
  # overriding parameters in non-hiera configurations (where solely relying
  # on lookup() simply does not work). Should be refactored when a better
  # solution is available.
  if !$vendor_version {
    $vendor_version_real = lookup("${module_name}::${vendor_type}::default_version")
  } else { $vendor_version_real = $vendor_version }
  $vendor_version_internal = regsubst($vendor_version_real, '\.', '', 'G')

  # Percona supports 'xtrabackup-v2', but this value cannot be used in our automatic
  # lookups, so we have to use a temporary value.
  $wsrep_sst_method_internal = regsubst($wsrep_sst_method, '-', '_', 'G')

  if !$additional_packages {
    $additional_packages_real = lookup("${module_name}::sst::${wsrep_sst_method_internal}::${vendor_type}::${vendor_version_internal}::additional_packages", {default_value => undef}) ? {
      undef => lookup("${module_name}::sst::${wsrep_sst_method_internal}::additional_packages", {default_value => undef}),
      default => lookup("${module_name}::sst::${wsrep_sst_method_internal}::${vendor_type}::${vendor_version_internal}::additional_packages")
    }
  } else { $additional_packages_real = $additional_packages }

  # The following compatibility layer (part 2) is only required for parameters
  # that may vary depending on the values of $vendor_version and $vendor_type.
  $params = {
    bootstrap_command => $bootstrap_command,
    client_package_name => $client_package_name,
    galera_package_name => $galera_package_name,
    libgalera_location => $libgalera_location,
    mysql_package_name => $mysql_package_name,
    mysql_service_name => $mysql_service_name,
  }.reduce({}) |$memo, $x| {
    # If a value was specified as class parameter, then use it. Otherwise use
    # lookup() to find a value in Hiera (or to fallback to default values from
    # module data).
    if !$x[1] {
      $_v = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}", {default_value => undef}) ? {
        undef => lookup("${module_name}::${vendor_type}::${$x[0]}"),
        default => lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}"),
      }
    } else {
      $_v = $x[1]
    }
    $memo + {$x[0] => $_v}
  }

  if $configure_repo {
    include galera::repo
    Class['::galera::repo'] -> Class['mysql::server']
  }

  if $configure_firewall {
    include galera::firewall
  }

  # Debian machines need some help
  if ($facts['os']['family'] == 'Debian') {
    include galera::debian
  }
  # as well as EL7 with MariaDB
  # Puppetlabs/mysql forces to use /var/run/mariadb and /var/log/mariadb but they don't exist
  # so mariadb service won't start. This is amended with galera::mariadb
  if $vendor_type == 'mariadb' and $facts['os']['family'] == 'RedHat' {
    include galera::mariadb
    Class['galera::mariadb'] -> Class['mysql::server::installdb']
  }

  if $status_check {
    include galera::status
  }

  if $validate_connection {
    include galera::validate
  }

  $node_list = join($galera_servers, ',')
  $_wsrep_cluster_address = {
    'mysqld' => {
      'wsrep_cluster_address' => "gcomm://${node_list}/"
    }
  }

  # XXX: The following is sort-of a compatibility layer. It passes all options
  # to the inline_epp() function. This way it is possible to use the values of
  # module parameters in MySQL/MariaDB options by specifying them in epp syntax.
  $wsrep_sst_auth_real = inline_epp($wsrep_sst_auth)
  $_default_options = $default_options.reduce({}) |$memo, $x| {
    # A nested hash contains the configuration options.
    if ($x[1] =~ Hash) {
      $_values = $x[1].reduce({}) |$m,$y| {
        # epp expects a string, so skip all other types.
        if ($y[1] =~ String) {
          $_v = inline_epp($y[1])
        } else {
          $_v = $y[1]
        }
        $m + {$y[0] => $_v}
      }
    } else {
      $_values = $x[1]
    }
    $memo + {$x[0] => $_values}
  }
  $_override_options = $override_options.reduce({}) |$memo, $x| {
    # A nested hash contains the configuration options.
    if ($x[1] =~ Hash) {
      $_values = $x[1].reduce({}) |$m,$y| {
        # epp expects a string, so skip all other types.
        if ($y[1] =~ String) {
          $_v = inline_epp($y[1])
        } else {
          $_v = $y[1]
        }
        $m + {$y[0] => $_v}
      }
    } else {
      $_values = $x[1]
    }
    $memo + {$x[0] => $_values}
  }

  # Finally merge options from all 3 sources.
  $options = $_default_options.deep_merge($_wsrep_cluster_address.deep_merge($override_options))

  if ($create_root_user =~ String) {
    $create_root_user_real = $create_root_user
  } else {
    if ($galera_master == $::fqdn) {
      # manage root user on the galera master
      $create_root_user_real = true
    } else {
      # skip manage root user on nodes that are not the galera master since
      # they should get a database with the root user already configured when
      # they sync from the master
      $create_root_user_real = false
    }
  }

  if (($create_root_my_cnf == true) and ($root_password =~ String)) {
    # Check if we can already login with the given password
    $my_cnf = "[client]\r\nuser=root\r\nhost=localhost\r\npassword='${root_password}'\r\n"

    exec { "create ${::root_home}/.my.cnf":
      command => "/bin/echo -e \"${my_cnf}\" > ${::root_home}/.my.cnf",
      onlyif  => [
        "${mysql_binary} --user=root --password=${root_password} -e 'select count(1);'",
        "/usr/bin/test `/bin/cat ${::root_home}/.my.cnf | ${grep_binary} -c \"password='${root_password}'\"` -eq 0",
        ],
      require => Service['mysqld'],
      before  => [Class['mysql::server::root_password']],
    }
  }

  class { '::mysql::server':
    package_name       => $params['mysql_package_name'],
    override_options   => $options,
    root_password      => $root_password,
    create_root_my_cnf => $create_root_my_cnf,
    create_root_user   => $create_root_user_real,
    service_enabled    => $service_enabled,
    purge_conf_dir     => $purge_conf_dir,
    service_name       => $params['mysql_service_name'],
    restart            => $mysql_restart,
  }

  file { $rundir:
    ensure  => directory,
    owner   => 'mysql',
    group   => 'mysql',
    require => Class['mysql::server::install'],
    before  => Class['mysql::server::installdb']
  }

  if ($manage_additional_packages and $additional_packages_real) {
    ensure_resource(package, $additional_packages_real,
    {
      ensure  => $package_ensure,
      before  => Class['mysql::server::install'],
    })
  }

  Package<| title == 'mysql_client' |> {
    name => $params['client_package_name']
  }

  package {[ $galera::params['galera_package_name'] ] :
    ensure => $galera_package_ensure,
    before => Class['mysql::server::install'],
  }

  if ($fqdn == $galera_master) {
    # If there are no other servers up and we are the master, the cluster
    # needs to be bootstrapped. This happens before the service is managed
    $server_list = join($galera_servers, ' ')

    if $manage_package_nmap {
      package { 'nmap':
        ensure => $package_ensure,
        before => Exec['bootstrap_galera_cluster']
      }
    }

    # NOTE: Galera >=5.7 on systemd systems should use mysqld_bootstrap.
    #       See http://galeracluster.com/documentation-webpages/startingcluster.html.
    # NOTE: MariaDB >=10.1 on systemd systems should use galera_new_cluster.
    #       See https://mariadb.com/kb/en/library/getting-started-with-mariadb-galera-cluster/.
    exec { 'bootstrap_galera_cluster':
      command  => $params['bootstrap_command'],
      unless   => "nmap -Pn -p ${wsrep_group_comm_port} ${server_list} | grep -q '${wsrep_group_comm_port}/tcp open'",
      require  => Class['mysql::server::installdb'],
      before   => Service['mysqld'],
      provider => shell,
      path     => '/usr/bin:/bin:/usr/sbin:/sbin'
    }

  }
}
