# @summary Configures a user and script that will check the status of the galera cluster.
# @api private
class galera::status (
) {
  if $galera::create_status_user {
    if $galera::status_allow != 'localhost' {
      # Create status user for the specified host
      mysql_user { "${galera::status_user}@${galera::status_allow}":
        ensure        => 'present',
        password_hash => mysql::password($galera::status_password),
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
      password_hash => mysql::password($galera::status_password),
    }
    -> mysql_grant { "${galera::status_user}@localhost/*.*":
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['USAGE'],
      table      => '*.*',
      user       => "${galera::status_user}@localhost",
    }
  }

  group { $galera::status_system_group:
    ensure => present,
    system => true,
  }

  user { $galera::status_system_user:
    *      => $galera::status_system_user_config,
    gid    => $galera::status_system_group,
    system => true,
  }

  file { $galera::status_script:
    content => epp('galera/clustercheck.epp'),
    owner   => $galera::status_system_user,
    group   => $galera::status_system_group,
    mode    => '0500',
  }

  case $galera::status_check {
    'xinetd': {
      xinetd::service { $galera::status_service_name:
        cps                     => $galera::status_cps,
        flags                   => $galera::status_flags,
        instances               => $galera::status_instances,
        log_on_failure          => $galera::status_log_on_failure,
        log_on_failure_operator => $galera::status_log_on_failure_operator,
        log_on_success          => $galera::status_log_on_success,
        log_on_success_operator => $galera::status_log_on_success_operator,
        log_type                => $galera::status_log_type,
        port                    => $galera::status_port,
        server                  => $galera::status_script,
        service_type            => $galera::status_service_type,
        user                    => $galera::status_system_user,
        require                 => [
          File[$galera::status_script],
          User[$galera::status_system_user]
        ],
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
      Exec<| title == 'bootstrap_galera_cluster' |> -> Class['xinetd']
    }
    'systemd': {
      # Generate a socket and service (xinetd style)
      systemd::manage_unit { "${galera::status_service_name}@.service":
        unit_entry    => {
          'Description' => "${galera::status_service_name} service",
          'After'       => ['network.target', 'network-online.target'],
          'Wants'       => ['network-online.target'],
        },
        service_entry => {
          'User'          => $galera::status_system_user,
          'Group'         => $galera::status_system_group,
          'StandardInput' => 'socket',
          'ExecStart'     => $galera::status_script,
        },
        require       => File[$galera::status_script],
      }
      -> systemd::manage_unit { "${galera::status_service_name}.socket":
        enable        => true,
        active        => true,
        unit_entry    => {
          'Description' => "${galera::status_service_name} socket",
        },
        socket_entry  => {
          'ListenStream' => $galera::status_port,
          'Accept'       => true,
        },
        install_entry => {
          'WantedBy' => 'sockets.target',
        },
      }

      # Migration path - remove xinetd service
      file { "/etc/xinetd.d/${galera::status_service_name}":
        ensure => 'absent',
      }
    }
    Boolean[false]: {
      # nothing todo here
    }
    default: {
      fail('unkown type of `galera::status_check` defined')
    }
  }
}
