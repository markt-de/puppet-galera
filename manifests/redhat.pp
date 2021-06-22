# @summary Adds workarounds to solve issues specific to RedHat-based systems.
# @api private
class galera::redhat {
  unless $galera::arbitrator {
    if $galera::vendor_type == 'mariadb' {
      if versioncmp($facts['os']['release']['major'], '7') >= 0 {
        # puppetlabs/mysql defaults to /var/run/mariadb and /var/log/mariadb but
        # they don't exist so the service won't start.
        file { '/var/log/mariadb':
          ensure => 'directory',
          before => Class['mysql::server::install'],
        }

        file { '/var/run/mariadb':
          ensure  => 'directory',
          owner   => 'mysql',
          group   => 'mysql',
          require => Class['mysql::server::install'],
          before  => Class['mysql::server::installdb'],
        }
      }
    } elsif $galera::vendor_type == 'percona' {
      if (versioncmp($galera::vendor_version_real, '5.6') >= 0) {
        # Perona installs two independent systemd services:
        #   mysql - for normal operation
        #   mysql@bootstrap - for bootstrapping a new cluster
        # However, after performing a bootstrap, only mysql@bootstrap is running.
        # The "mysql" service remains in state stopped, which causes errors when
        # puppetlabs/mysql tries to start it while the bootstrap service is
        # already running.
        # To mitigate this, we perform the bootstrap, stop the bootstrap service
        # and wait for puppetlabs/mysql to start the normal mysql service. After
        # a clean shutdown and with no other node online, this node should be
        # able to startup as primary node.
        service { 'mysql@bootstrap':
          ensure => 'stopped',
          before => Service[$galera::mysql_service_name],
        }
        Exec<| title == 'bootstrap_galera_cluster' |> -> Service['mysql@bootstrap']
      }
    }
  }
}
