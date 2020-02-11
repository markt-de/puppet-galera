# @summary Adds workarounds to solve issues specific to RedHat-based systems.
# @api private
class galera::redhat {
  if versioncmp($facts['os']['release']['major'], '7') >=0 {
    if ($galera::arbitrator == false) {
      # puppetlabs/mysql forces to use /var/run/mariadb and /var/log/mariadb but
      # they don't exist so the service won't start.
      if $galera::vendor_type == 'mariadb' {
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
    }
  }
}
