# == Class: galera::debian
#
# Fixes Debian specific compatibility issues
#
class galera::debian {

  if ($::osfamily != 'Debian') {
    warn('the galera::debian class has been included on a non-debian host')
  }

  # Debian policy will autostart the non galera mysql after
  # package install, so kill it if the package is
  # installed during this puppet run
  exec { 'clean_up_ubuntu':
    command     => 'service mysql stop',
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
    subscribe   => Package['mysql-server'],
    before      => Class['mysql::server::config'],
    require     => Class['mysql::server::install'],
  }

  if ($::fqdn == $galera::galera_master) {
    # Debian sysmaint pw will be set on the master,
    # and needs to be consistent across the cluster.
    mysql_user { 'debian-sys-maint@localhost':
      ensure        => 'present',
      password_hash => mysql_password($galera::deb_sysmaint_password),
      provider      => 'mysql',
      require       => File['/root/.my.cnf'],
    }

    file { '/etc/mysql/debian.cnf':
      ensure  => present,
      owner   => 'mysql',
      group   => 'mysql',
      content => template('galera/debian.cnf.erb'),
      require => Mysql_user['debian-sys-maint@localhost'],
    }
  } else {
    # Ensure this file is changed only after stopping the service or
    # said service stop operation will fail
    file { '/etc/mysql/debian.cnf':
      ensure  => present,
      owner   => 'mysql',
      group   => 'mysql',
      content => template('galera/debian.cnf.erb'),
      require => Exec['clean_up_ubuntu'],
      before  => Service['mysql'],
    }
  }
  # Ensure mysql server is installed before writing debian.cnf, since the
  # package will create /etc/mysql
  Package['mysql-server'] -> File['/etc/mysql/debian.cnf']
}
