# @summary Configures a user and script that will check the status of the galera cluster.
# @api private
class galera::status (
){
  if ! $galera::status_password {
    fail('galera::status_password unset. Please specify a password for the clustercheck MySQL user.')
  }

  if $galera::create_status_user {
    if $galera::status_allow != 'localhost' {
      # Create status user for the specified host
      mysql_user { "${galera::status_user}@${galera::status_allow}":
        ensure        => 'present',
        password_hash => mysql_password($galera::status_password),
        require       => [Service['mysqld']]
      }
      -> mysql_grant { "${galera::status_user}@${galera::status_allow}/*.*":
        ensure     => 'present',
        options    => [ 'GRANT' ],
        privileges => [ 'USAGE' ],
        table      => '*.*',
        user       => "${galera::status_user}@${galera::status_allow}",
        before     => Anchor['mysql::server::end']
      }
      if $galera::create_root_my_cnf {
        Exec['create .my.cnf for user root'] -> Mysql_user["${galera::status_user}@${galera::status_allow}"]
      }
    }

    # Create status user for localhost (required by this module)
    mysql_user { "${galera::status_user}@localhost":
      ensure        => 'present',
      password_hash => mysql_password($galera::status_password),
      require       => [Service['mysqld']]
    }
    -> mysql_grant { "${galera::status_user}@localhost/*.*":
      ensure     => 'present',
      options    => [ 'GRANT' ],
      privileges => [ 'USAGE' ],
      table      => '*.*',
      user       => "${galera::status_user}@localhost",
      before     => Anchor['mysql::server::end']
    }
    if $galera::create_root_my_cnf {
      Exec['create .my.cnf for user root'] -> Mysql_user["${galera::status_user}@localhost"]
    }
  }

  group { 'clustercheck':
    ensure => present,
    system => true,
  }

  user { 'clustercheck':
    shell  => '/bin/false',
    home   => '/var/empty',
    gid    => 'clustercheck',
    system => true,
    before => File['/usr/local/bin/clustercheck'],
  }

  file { '/usr/local/bin/clustercheck':
    content => epp('galera/clustercheck.epp'),
    owner   => 'clustercheck',
    group   => 'clustercheck',
    mode    => '0500',
    before  => Anchor['mysql::server::end'],
  }

  xinetd::service { 'mysqlchk':
    server                  => '/usr/local/bin/clustercheck',
    port                    => $galera::status_port,
    user                    => 'clustercheck',
    flags                   => 'REUSE',
    service_type            => 'UNLISTED',
    log_on_success          => $galera::status_log_on_success,
    log_on_success_operator => $galera::status_log_on_success_operator,
    log_on_failure          => $galera::status_log_on_failure,
    require                 => [
      File['/usr/local/bin/clustercheck'],
      User['clustercheck'],
      Class['mysql::server::install']],
    before                  => Anchor['mysql::server::end'],
  }
}
