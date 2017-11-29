# == Class: galera::debian
#
# Fixes Debian specific compatibility issues
#
class galera::debian {
  if ($::osfamily != 'Debian') {
    warn('the galera::debian class has been included on a non-debian host')
  }

  # puppetlabs-mysql now places config before installing the package, which causes issues
  # if the service is started as part of package installs, as it is on debians. Resolve this
  # by putting a default my.cnf in place before installing the package, then putting the
  # real config file back after installing the package but before starting the service for real
  file { '/etc/mysql/puppet_debfix.cnf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('galera/debian_default_my_cnf'),
    require => Class['mysql::server::config'],
  } ~>

  exec { 'fix_galera_config_errors_episode_I':
    command     => 'mv -f /etc/mysql/my.cnf /tmp/my.cnf && cp -f /etc/mysql/puppet_debfix.cnf /etc/mysql/my.cnf',
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
  } ~>

  exec { 'fix_galera_config_errors_episode_II':
    command     => 'cp -f /tmp/my.cnf /etc/mysql/my.cnf',
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
    require     => Class['mysql::server::install'],
    before      => Class['mysql::server::installdb'],
  }

  # Debian policy will autostart the non galera mysql after
  # package install, so kill it if the package is
  # installed during this puppet run
  exec { 'clean_up_ubuntu':
    command     => 'service mysql stop',
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
    subscribe   => Package['mysql-server'],
    before      => Class['mysql::server::installdb'],
    require     => Class['mysql::server::install'],
  }

  # Assign this locally so that it is in scope for the template below.
  # Required for Puppet 4
  $deb_sysmaint_password = $galera::deb_sysmaint_password

  if ($::fqdn == $galera::galera_master) {

    # Debian sysmaint pw will be set on the master,
    # and needs to be consistent across the cluster.
    mysql_user { 'debian-sys-maint@localhost':
      ensure        => 'present',
      password_hash => mysql_password($deb_sysmaint_password),
      provider      => 'mysql',
      require       => File["${::root_home}/.my.cnf"],
    }

    mysql_grant { 'debian-sys-maint@localhost/*.*':
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['ALL'],
      table      => '*.*',
      user       => 'debian-sys-maint@localhost',
    }

    file { '/etc/mysql/debian.cnf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template('galera/debian.cnf.erb'),
      require => Mysql_user['debian-sys-maint@localhost'],
    }
  } else {
    # Ensure this file is changed only after stopping the service or
    # said service stop operation will fail
    file { '/etc/mysql/debian.cnf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template('galera/debian.cnf.erb'),
      require => Exec['clean_up_ubuntu'],
      before  => Service['mysqld'],
    }
  }

  # Ensure mysql server is installed before writing debian.cnf, since the
  # package will create /etc/mysql
  Package['mysql-server'] -> File['/etc/mysql/debian.cnf']
}
