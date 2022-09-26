# @summary Configures a user and script that will check the status of the galera cluster.
# @api private
class galera::status (
) {
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
        options    => ['GRANT'],
        privileges => ['USAGE'],
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
      options    => ['GRANT'],
      privileges => ['USAGE'],
      table      => '*.*',
      user       => "${galera::status_user}@localhost",
    }
  }


  group { 'clustercheck':
    ensure => present,
    system => true,
  }->
  user { 'clustercheck':
    shell  => '/bin/false',
    home   => '/var/empty',
    gid    => 'clustercheck',
    system => true,
  }->
  file { '/usr/local/bin/clustercheck':
    content => epp('galera/clustercheck.epp'),
    owner   => 'clustercheck',
    group   => 'clustercheck',
    mode    => '0500',
  }

  if $::osfamily == 'FreeBSD' {
    File['/usr/local/bin/clustercheck'] -> xinetd::service { 'mysqlchk':
        server                  => '/usr/local/bin/clustercheck',
        port                    => $galera::status_port,
        user                    => 'clustercheck',
        flags                   => 'REUSE',
        service_type            => 'UNLISTED',
        log_on_success          => $galera::status_log_on_success,
        log_on_success_operator => $galera::status_log_on_success_operator,
        log_on_failure          => $galera::status_log_on_failure,
    }
    Exec<| title == 'bootstrap_galera_cluster' |> -> Class['xinetd']
  }
  else {
    File['/usr/local/bin/clustercheck'] -> file {'/lib/systemd/system/mysqlchk.socket':
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => epp('galera/mysqlchk.socket.epp')
    }->
    file {'/lib/systemd/system/mysqlchk@.service':
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => epp('galera/mysqlchk.service.epp')
    }~>
    exec { 'mysqlchk-systemd-reload':
      command     => 'systemctl daemon-reload',
      path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
      refreshonly => true,
    }

    # remove xinetd service
    file {'/etc/xinetd.d/mysqlchk':
      ensure => 'absent',
    }
  }
}
