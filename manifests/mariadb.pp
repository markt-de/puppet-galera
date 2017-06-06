# Class galera::mariadb
#
# Sets some specific resources when using the mariadb distribution of
# mysql-galera
#
class galera::mariadb {
  if versioncmp($::operatingsystemmajrelease, '7') >=0 {
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
