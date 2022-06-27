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
      }
      -> mysql_grant { "${galera::status_user}@${galera::status_allow}/*.*":
        ensure     => 'present',
        options    => [ 'GRANT' ],
        privileges => [ 'USAGE' ],
        table      => '*.*',
        user       => "${galera::status_user}@${galera::status_allow}",
      }
    }

    # Create status user for localhost (required by this module)
    mysql_user { "${galera::status_user}@localhost":
      ensure        => 'present',
      password_hash => mysql_password($galera::status_password),
    }
    -> mysql_grant { "${galera::status_user}@localhost/*.*":
      ensure     => 'present',
      options    => [ 'GRANT' ],
      privileges => [ 'USAGE' ],
      table      => '*.*',
      user       => "${galera::status_user}@localhost",
    }
  }

  if ($galera::status_group != 'nobody') {
    group { $galera::status_group:
      ensure => present,
      system => true,
    }
  }

  if ($galera::status_user != 'nobody') {
    user { $galera::status_user:
      shell  => '/bin/false',
      home   => '/var/empty',
      gid    => 'clustercheck',
      system => true,
      before => File['/usr/local/bin/clustercheck'],
    }
  }

  file { '/usr/local/bin/clustercheck':
    content => epp('galera/clustercheck.epp'),
    owner   => $galera::status_user,
    group   => $galera::status_group,
    mode    => '0500',
  }

  xinetd::service { 'mysqlchk':
    server                  => '/usr/local/bin/clustercheck',
    port                    => $galera::status_port,
    user                    => $galera::status_user,
    group                   => $galera::status_group,
    flags                   => $galera::status_flags,
    service_type            => $galera::status_service_type,
    cps                     => $galera::status_cps,
    instances               => $galera::status_instances,
    log_type                => $galera::status_log_type,
    log_on_success          => $galera::status_log_on_success,
    log_on_success_operator => $galera::status_log_on_success_operator,
    log_on_failure          => $galera::status_log_on_failure,
    log_on_failure_operator => $galera::status_log_on_failure_operator,
    require                 => [
      File['/usr/local/bin/clustercheck'],
      User[$galera::status_user]
    ],
    before                  => Anchor['mysql::server::end'],
  }

  # Postpone the xinetd stuff. This is necessary in order to avoid package
  # conflicts. On some platforms xinetd depends on MySQL libs. If installed
  # too early it will install the wrong MySQL libs. This may cause the
  # installation of the Galera packages to fail.
  # This has been first observed on Debian 9 with Codership Galera 5.7 where
  # the package installation just ended with a conflict instead of replacing
  # the wrong MySQL libs. The root cause is likely a packaging bug in the
  # Codership distribution, since this issue could not be reproduced for
  # Percona.
  Exec<| title == 'bootstrap_galera_cluster' |> -> Class['::xinetd']
}
