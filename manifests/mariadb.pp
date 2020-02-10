# @summary Adds workarounds to solve issues when using the MariaDB distribution of galera.
# @api private
class galera::mariadb {
  if versioncmp($facts['os']['release']['major'], '7') >=0 {
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
